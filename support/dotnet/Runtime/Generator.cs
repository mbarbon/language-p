using org.mbarbon.p.values;

using System.Reflection.Emit;
using System.Reflection;
using Microsoft.Linq.Expressions;
using System.Collections.Generic;

namespace org.mbarbon.p.runtime
{
    public class ModuleGenerator
    {
        private struct SubInfo
        {
            internal SubInfo(string method, string sub)
            {
                MethodName = method;
                SubName = sub;
            }

            internal string MethodName;
            internal string SubName;
        }

        public ModuleGenerator(TypeBuilder class_builder)
        {
            ClassBuilder = class_builder;
            Initializers = new List<Expression>();
            Subroutines = new List<SubInfo>();
            InitRuntime = Expression.Parameter(typeof(Runtime), "runtime");
        }

        public FieldInfo AddField(Expression initializer)
        {
            string field_name = "const_" + Initializers.Count.ToString();
            FieldInfo field = ClassBuilder.DefineField(field_name, typeof(Scalar), FieldAttributes.Private|FieldAttributes.Static);
            var init = Expression.Assign(Expression.Field(null, field), initializer);
            Initializers.Add(init);

            return field;
        }

        public void AddMethod(Subroutine sub)
        {
            var sg = new SubGenerator(this);
            bool is_main = sub.Name.Length == 0;
            var body = sg.Generate(sub, is_main);
            string suffix = is_main         ? "main" :
                           sub.Name != null ? sub.Name :
                                             "anonymous";
            string method_name = "sub_" + suffix + "_" + MethodIndex++.ToString();
            MethodBuilder method_builder = ClassBuilder.DefineMethod(method_name, MethodAttributes.Static|MethodAttributes.Public);
            body.CompileToMethod(method_builder);

            Subroutines.Add(new SubInfo(method_name, is_main ? null : sub.Name));
        }

        public void AddInitMethod()
        {
            MethodBuilder helper = ClassBuilder.DefineMethod("InitModule", MethodAttributes.Public|MethodAttributes.Static,
                                                         typeof(void), new System.Type[] { typeof(Runtime) });
            if (Initializers.Count == 0)
                Initializers.Add(Expression.Empty());
            var constants_init = Expression.Lambda(Expression.Block(Initializers), InitRuntime);
            constants_init.CompileToMethod(helper);
        }

        public Code CompleteGeneration(Runtime runtime)
        {
            AddInitMethod();

            Code main = null;
            System.Type mod = ClassBuilder.CreateType();
            mod.GetMethod("InitModule").Invoke(null, new object[] { runtime });

            foreach (SubInfo si in Subroutines)
            {
                MethodInfo method = mod.GetMethod(si.MethodName);
                Code c = new Code(System.Delegate.CreateDelegate(typeof(Code.Sub), method));
                if (si.SubName == null)
                    main = c;
                else
                    runtime.SymbolTable.SetCode(runtime, si.SubName, c);
            }

            return main;
        }

        private TypeBuilder ClassBuilder;
        private List<Expression> Initializers;
        private List<SubInfo> Subroutines;
        private int MethodIndex = 0;
        public ParameterExpression InitRuntime;
    }

    public class SubGenerator
    {
        public SubGenerator(ModuleGenerator module_generator)
        {
            Runtime = Expression.Parameter(typeof(Runtime), "runtime");
            Arguments = Expression.Parameter(typeof(org.mbarbon.p.values.Array), "args");
            Context = Expression.Parameter(typeof(Opcode.Context), "context");
            Pad = Expression.Parameter(typeof(ScratchPad), "pad");
            Variables = new List<ParameterExpression>();
            Lexicals = new List<ParameterExpression>();
            BlockLabels = new List<LabelTarget>();
            Blocks = new List<Expression>();
            ModuleGenerator = module_generator;
        }

        private ParameterExpression GetVariable(int index)
        {
            while (Variables.Count <= index)
                Variables.Add(Expression.Variable(typeof(IAny)));

            return Variables[index];
        }

        private ParameterExpression GetLexical(int index)
        {
            while (Lexicals.Count <= index)
                Lexicals.Add(Expression.Variable(typeof(IAny)));

            return Lexicals[index];
        }

        public LambdaExpression Generate(Subroutine sub, bool is_main)
        {
            IsMain = is_main;
            SubLabel = Expression.Label(typeof(IAny));

            for (int i = 0; i < sub.BasicBlocks.Length; ++i)
                BlockLabels.Add(Expression.Label());
            for (int i = 0; i < sub.BasicBlocks.Length; ++i)
            {
                List<Expression> exps = new List<Expression>();
                exps.Add(Expression.Label(BlockLabels[i]));
                Generate(sub.BasicBlocks[i], exps);
                Blocks.Add(Expression.Block(typeof(IAny), exps));
            }
            if (Lexicals.Count != 0)
            {
                List<Expression> init_exps = new List<Expression>();
                foreach (var lex in Lexicals)
                {
                    init_exps.Add(Expression.Assign(lex, Expression.New(typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime) }),
                                                                   Runtime)));
                }
                Blocks.Insert(0, Expression.Block(typeof(void), init_exps));
            }

            Variables.InsertRange(0, Lexicals);

            var block = Expression.Block(typeof(IAny), Variables, Blocks);
            var args = new ParameterExpression[] { Runtime, Context, Pad, Arguments };
            return Expression.Lambda<Code.Sub>(Expression.Label(SubLabel, block), args);
        }

        public void Generate(BasicBlock bb, List<Expression> expressions)
        {
            foreach (var o in bb.Opcodes)
            {
                expressions.Add(Generate(o));
            }
        }

        public Expression Generate(Opcode op)
        {
            switch(op.Number)
            {
            case Opcode.OpNumber.OP_FRESH_STRING:
            case Opcode.OpNumber.OP_CONSTANT_STRING:
            {
                var ctor = typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(string) });
                return Expression.New(ctor, new Expression[] { Runtime, Expression.Constant(((ConstantString)op).Value) });
            }
            case Opcode.OpNumber.OP_CONSTANT_UNDEF:
            {
                var ctor = typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime) });
                return Expression.New(ctor, new Expression[] { Runtime });
            }
            case Opcode.OpNumber.OP_CONSTANT_INTEGER:
            {
                var ctor = typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(int) });
                var init = Expression.New(ctor, new Expression[] { ModuleGenerator.InitRuntime, Expression.Constant(((ConstantInt)op).Value) });
                FieldInfo field = ModuleGenerator.AddField(init);

                return Expression.Field(null, field);
            }
            case Opcode.OpNumber.OP_GLOBAL:
            {
                Global gop = (Global)op;
                var st = typeof(Runtime).GetField("SymbolTable");
                string name = null;
                switch (gop.Slot)
                {
                case 1:
                    name = "GetOrCreateScalar";
                    break;
                case 2:
                    name = "GetOrCreateArray";
                    break;
                case 3:
                    name = "GetOrCreateHash";
                    break;
                case 4:
                    name = "GetCode";
                    break;
                case 5:
                    name = "GetOrCreateGlob";
                    break;
                case 7:
                    name = "GetOrCreateHandle";
                    break;
                default:
                    throw new System.Exception(string.Format("Unhandled slot {0:D}", gop.Slot));
                }
                var gets = typeof(SymbolTable).GetMethod(name);
                return Expression.Call(Expression.Field(Runtime, st), gets, Runtime, Expression.Constant(gop.Name));
            }
            case Opcode.OpNumber.OP_MAKE_LIST:
            {
                List<Expression> data = new List<Expression>();
                foreach (var i in op.Childs)
                    data.Add(Generate(i));
                return Expression.New(typeof(org.mbarbon.p.values.List).GetConstructor(new System.Type[] {typeof(Runtime), typeof(IAny[])}),
                                    new Expression[] { Runtime, Expression.NewArrayInit(typeof(IAny), data) });
            }
            case Opcode.OpNumber.OP_PRINT:
            {
                return Expression.Call(typeof(Builtins).GetMethod("Print"), Runtime,
                                     Expression.Convert(Generate(op.Childs[0]), typeof(org.mbarbon.p.values.List)));
            }
            case Opcode.OpNumber.OP_END:
            {
                return Expression.Return(SubLabel, Expression.Constant(null, typeof(IAny)), typeof(IAny));
            }
            case Opcode.OpNumber.OP_RETURN:
            {
                Expression empty = Expression.New(typeof(org.mbarbon.p.values.List).GetConstructor(new System.Type[] { typeof(Runtime) }), Runtime);
                if (op.Childs.Length == 0)
                {
                    return Expression.Return(SubLabel, empty, typeof(IAny));
                }
                else
                {
                    ParameterExpression val = Expression.Variable(typeof(IAny), "ret");
                    Expression assign = Expression.Assign(val, Generate(op.Childs[0]));
                    Expression iflist =
                        Expression.Condition(Expression.Equal(Context, Expression.Constant(Opcode.Context.LIST)),
                                           val, empty, typeof(IAny));
                    Expression retscalar =
                        Expression.Call(val, typeof(IAny).GetMethod("AsScalar"), Runtime);
                    Expression ifscalar =
                        Expression.Condition(Expression.Equal(Context, Expression.Constant(Opcode.Context.SCALAR)),
                                           retscalar, iflist, typeof(IAny));

                    return Expression.Return(SubLabel, Expression.Block(typeof(IAny), new ParameterExpression[] { val },
                                                                   new Expression[] { assign, ifscalar }),
                                           typeof(IAny));
                }
            }
            case Opcode.OpNumber.OP_ASSIGN:
            {
                return Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("Assign"), Runtime,
                                     Generate(op.Childs[1]));
            }
            case Opcode.OpNumber.OP_GET:
            {
                return GetVariable(((GetSet)op).Variable);
            }
            case Opcode.OpNumber.OP_SET:
            {
                return Expression.Assign(GetVariable(((GetSet)op).Variable),
                                       Generate(op.Childs[0]));
            }
            case Opcode.OpNumber.OP_JUMP:
            {
                return Expression.Goto(BlockLabels[((Jump)op).To], typeof(IAny));
            }
            case Opcode.OpNumber.OP_JUMP_IF_S_EQ:
            {
                Expression cmp = Expression.Equal(Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsString"), Runtime),
                                               Expression.Call(Generate(op.Childs[1]), typeof(IAny).GetMethod("AsString"), Runtime));
                Expression jump = Expression.Goto(BlockLabels[((Jump)op).To], typeof(IAny));

                return Expression.IfThen(cmp, jump);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_EQ:
            {
                Expression cmp = Expression.Equal(Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsFloat"), Runtime),
                                               Expression.Call(Generate(op.Childs[1]), typeof(IAny).GetMethod("AsFloat"), Runtime));
                Expression jump = Expression.Goto(BlockLabels[((Jump)op).To], typeof(IAny));

                return Expression.IfThen(cmp, jump);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_GE:
            {
                Expression cmp = Expression.GreaterThanOrEqual(Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsFloat"), Runtime),
                                                           Expression.Call(Generate(op.Childs[1]), typeof(IAny).GetMethod("AsFloat"), Runtime));
                Expression jump = Expression.Goto(BlockLabels[((Jump)op).To], typeof(IAny));

                return Expression.IfThen(cmp, jump);
            }
            case Opcode.OpNumber.OP_JUMP_IF_TRUE:
            {
                Expression cmp = Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsBoolean"), Runtime);
                Expression jump = Expression.Goto(BlockLabels[((Jump)op).To], typeof(IAny));

                return Expression.IfThen(cmp, jump);
            }
            case Opcode.OpNumber.OP_LOG_NOT:
            {
                return Expression.New(typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(bool) }), Runtime,
                                    Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsBoolean"), Runtime));
            }
            case Opcode.OpNumber.OP_DEFINED:
            {
                return Expression.New(typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(bool) }), Runtime,
                                    Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("IsDefined"), Runtime));
            }
            case Opcode.OpNumber.OP_CONCAT:
            {
                Expression s1 = Expression.Call(Generate(op.Childs[0]),
                                             typeof(IAny).GetMethod("AsString"), Runtime);
                Expression s2 = Expression.Call(Generate(op.Childs[1]),
                                             typeof(IAny).GetMethod("AsString"), Runtime);
                return Expression.New(typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(string) }), Runtime,
                                    Expression.Call(typeof(string).GetMethod("Concat", new System.Type[] { typeof(string), typeof(string) }), s1, s2));
            }
            case Opcode.OpNumber.OP_CONCAT_ASSIGN:
            {
                return Expression.Call(Expression.Convert(Generate(op.Childs[0]), typeof(Scalar)),
                                     typeof(IAny).GetMethod("ConcatAssign"), Runtime, Generate(op.Childs[1]));
            }
            case Opcode.OpNumber.OP_ARRAY_LENGTH:
            {
                Expression len = Expression.Call(Expression.Convert(Generate(op.Childs[0]), typeof(org.mbarbon.p.values.Array)),
                                              typeof(org.mbarbon.p.values.Array).GetMethod("GetCount"),
                                              Runtime);
                Expression len_1 = Expression.Subtract(len, Expression.Constant(1));
                return Expression.New(typeof(Scalar).GetConstructor(new System.Type[] {typeof(Runtime), typeof(int)}),
                                    new Expression[] { Runtime, len_1 });
            }
            case Opcode.OpNumber.OP_ADD:
            {
                Expression sum = Expression.Add(Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsFloat"), Runtime),
                                             Expression.Call(Generate(op.Childs[1]), typeof(IAny).GetMethod("AsFloat"), Runtime));
                return Expression.New(typeof(Scalar).GetConstructor(new System.Type[] {typeof(Runtime), typeof(double)}),
                                    new Expression[] { Runtime, sum });
            }
            case Opcode.OpNumber.OP_SUBTRACT:
            {
                Expression sum = Expression.Subtract(Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsFloat"), Runtime),
                                                  Expression.Call(Generate(op.Childs[1]), typeof(IAny).GetMethod("AsFloat"), Runtime));
                return Expression.New(typeof(Scalar).GetConstructor(new System.Type[] {typeof(Runtime), typeof(double)}),
                                    new Expression[] { Runtime, sum });
            }
            case Opcode.OpNumber.OP_ARRAY_ELEMENT:
            {
                return Expression.Call(Generate(op.Childs[1]), typeof(Array).GetMethod("GetItemOrUndef"),
                                     Runtime, Generate(op.Childs[0]));
            }
            case Opcode.OpNumber.OP_HASH_ELEMENT:
            {
                return Expression.Call(Generate(op.Childs[1]), typeof(Hash).GetMethod("GetItemOrUndef"),
                                     Runtime, Generate(op.Childs[0]));
            }
            case Opcode.OpNumber.OP_LEXICAL:
            {
                Lexical lx = (Lexical)op;

                return lx.Index == 0 && !IsMain ? Arguments : GetLexical(lx.Index);
            }
            case Opcode.OpNumber.OP_LEXICAL_CLEAR:
            {
                Lexical lx = (Lexical)op;

                return Expression.Assign(GetLexical(lx.Index), Expression.Constant(null, typeof(IAny)));
            }
            case Opcode.OpNumber.OP_LEXICAL_PAD:
            {
                Lexical lx = (Lexical)op;

                return Expression.ArrayIndex(Pad, Expression.Constant(lx.Index));
            }
            case Opcode.OpNumber.OP_CALL:
            {
                return Expression.Call(Generate(op.Childs[1]), typeof(Code).GetMethod("Call"),
                                     Runtime, Context, Generate(op.Childs[0]));
            }
            default:
                throw new System.Exception(string.Format("Unhandled opcode {0:S}", op.Number.ToString()));
            }
        }

        private LabelTarget SubLabel;
        private ParameterExpression Runtime, Arguments, Context, Pad;
        private List<ParameterExpression> Variables, Lexicals;
        private List<LabelTarget> BlockLabels;
        private List<Expression> Blocks;
        private bool IsMain;
        private ModuleGenerator ModuleGenerator;
    }

    public class Generator
    {
        public Generator(Runtime r)
        {
            Runtime = r;
        }

        public Code Generate(string assembly_name, CompilationUnit cu)
        {
            var file = new System.IO.FileInfo(cu.FileName);
            AssemblyName asm_name = new AssemblyName(assembly_name != null ? assembly_name : file.Name);
            AssemblyBuilder asm_builder =
                System.AppDomain.CurrentDomain.DefineDynamicAssembly(asm_name,
                                                              AssemblyBuilderAccess.RunAndSave);
            ModuleBuilder mod_builder = asm_builder.DefineDynamicModule(asm_name.Name, asm_name.Name + ".dll");
            // FIXME should at least be the module name with which the file was loaded, in case
            //       multiple modules are compiled to the same file; works for now
            TypeBuilder perl_module = mod_builder.DefineType(file.Name, TypeAttributes.Public);
            ModuleGenerator perl_mod_generator = new ModuleGenerator(perl_module);

            foreach (var sub in cu.Subroutines)
                perl_mod_generator.AddMethod(sub);

            return perl_mod_generator.CompleteGeneration(Runtime);
        }

        Runtime Runtime;
    }
}
