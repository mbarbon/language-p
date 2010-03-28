using org.mbarbon.p.values;

using System.Reflection.Emit;
using System.Reflection;
using System.Linq.Expressions;
using Microsoft.Linq.Expressions;
using Microsoft.Scripting.Ast;
using System.Collections.Generic;
using Type = System.Type;
using IEnumerator = System.Collections.IEnumerator;
using DebuggableAttribute = System.Diagnostics.DebuggableAttribute;
using DebugInfoGenerator = Microsoft.Runtime.CompilerServices.DebugInfoGenerator;
using MemoryStream = System.IO.MemoryStream;
using BinaryFormatter = System.Runtime.Serialization.Formatters.Binary.BinaryFormatter;

namespace org.mbarbon.p.runtime
{
    internal class ModuleGenerator
    {
        internal struct SubInfo
        {
            internal SubInfo(string method, Subroutine sub, FieldInfo codefield)
            {
                MethodName = method;
                CodeField = codefield;
                Subroutine = sub;
            }

            internal Subroutine Subroutine;
            internal string MethodName;
            internal FieldInfo CodeField;

            internal string SubName
            {
                get { return Subroutine.Name; }
            }

            internal LexicalInfo[] Lexicals
            {
                get { return Subroutine.Lexicals; }
            }

            internal bool IsMain
            {
                get { return Subroutine.IsMain; }
            }
        }

        public ModuleGenerator(TypeBuilder class_builder)
        {
            ClassBuilder = class_builder;
            Initializers = new List<Expression>();
            Subroutines = new List<SubInfo>();
            InitRuntime = Expression.Parameter(typeof(Runtime), "runtime");
        }

        public FieldInfo AddField(Expression initializer, Type type)
        {
            string field_name = "const_" + Initializers.Count.ToString();
            FieldInfo field =
                ClassBuilder.DefineField(
                    field_name, type,
                    FieldAttributes.Private|FieldAttributes.Static);
            var init =
                Expression.Assign(
                    Expression.Field(null, field),
                    initializer);
            Initializers.Add(init);

            return field;
        }

        public FieldInfo AddField(Expression initializer)
        {
            return AddField(initializer, typeof(P5Scalar));
        }

        public void AddRegexInfo(Subroutine sub)
        {
            FieldInfo field = ClassBuilder.DefineField(
                "regex_" + MethodIndex++.ToString(), typeof(Regex),
                FieldAttributes.Private|FieldAttributes.Static);

            Subroutines.Add(new SubInfo(null, sub, field));
        }

        public void AddSubInfo(Subroutine sub)
        {
            bool is_main = sub.IsMain;
            string suffix = is_main          ? "main" :
                            sub.Name != null ? sub.Name :
                                               "anonymous";
            string method_name = "sub_" + suffix + "_" +
                                     MethodIndex++.ToString();
            FieldInfo field = ClassBuilder.DefineField(
                method_name + "_code", typeof(P5Code),
                FieldAttributes.Private|FieldAttributes.Static);

            Subroutines.Add(new SubInfo(method_name, sub, field));
        }

        public void AddRegex(int index, Subroutine sub)
        {
            Regex regex = GenerateRegex(sub);
            var stream = new MemoryStream();
            var formatter = new BinaryFormatter();

            formatter.Serialize(stream, regex);

            var bytes = new List<Expression>();
            foreach (var b in stream.ToArray())
                bytes.Add(Expression.Constant(b));

            var byteField = AddField(
                Expression.NewArrayInit(typeof(byte), bytes),
                typeof(byte[]));
            var memStream = Expression.New(
                typeof(MemoryStream).GetConstructor(
                    new Type[] { typeof(byte[]) }),
                Expression.Field(null, byteField));
            var deserializer = Expression.New(
                typeof(BinaryFormatter).GetConstructor(
                    new Type[0]));
            var init = Expression.Convert(
                Expression.Call(
                    deserializer,
                    typeof(BinaryFormatter).GetMethod(
                        "Deserialize",
                        new Type[] { typeof(System.IO.Stream) }),
                    memStream),
                typeof(Regex));

            Initializers.Add(
                Expression.Assign(
                    Expression.Field(null, Subroutines[index].CodeField),
                    init));
        }

        public Regex GenerateRegex(Subroutine sub)
        {
            var quantifiers = new List<RxQuantifier>();
            var ops = new List<Regex.Op>();
            var targets = new List<int>();
            var exact = new List<string>();
            int captures = 0;

            foreach (var bb in sub.BasicBlocks)
            {
                targets.Add(ops.Count);

                foreach (var op in bb.Opcodes)
                {
                    switch (op.Number)
                    {
                    case Opcode.OpNumber.OP_RX_BEGINNING:
                    case Opcode.OpNumber.OP_RX_END_OR_NEWLINE:
                    case Opcode.OpNumber.OP_RX_START_MATCH:
                        ops.Add(new Regex.Op(op.Number));
                        break;
                    case Opcode.OpNumber.OP_RX_ACCEPT:
                    {
                        var ac = (RegexAccept)op;

                        ops.Add(new Regex.Op(ac.Number, ac.Groups));
                        break;
                    }
                    case Opcode.OpNumber.OP_RX_EXACT:
                    {
                        var ex = (RegexExact)op;

                        ops.Add(new Regex.Op(ex.Number, exact.Count));
                        exact.Add(ex.String);
                        break;
                    }
                    case Opcode.OpNumber.OP_RX_START_GROUP:
                    {
                        var gr = (RegexStartGroup)op;

                        ops.Add(new Regex.Op(gr.Number, gr.To));
                        break;
                    }
                    case Opcode.OpNumber.OP_RX_TRY:
                    {
                        var tr = (RegexTry)op;

                        ops.Add(new Regex.Op(tr.Number, tr.To));
                        break;
                    }
                    case Opcode.OpNumber.OP_RX_QUANTIFIER:
                    {
                        var qu = (RegexQuantifier)op;

                        ops.Add(new Regex.Op(qu.Number, quantifiers.Count));
                        quantifiers.Add(
                            new RxQuantifier(qu.Min, qu.Max, qu.Greedy != 0,
                                             qu.To, qu.Group, qu.SubgroupsStart,
                                             qu.SubgroupsEnd));
                        if (captures <= qu.Group)
                            captures = qu.Group + 1;

                        break;
                    }
                    case Opcode.OpNumber.OP_RX_CAPTURE_START:
                    case Opcode.OpNumber.OP_RX_CAPTURE_END:
                    {
                        var ca = (RegexCapture)op;

                        ops.Add(new Regex.Op(ca.Number, ca.Group));
                        if (captures <= ca.Group)
                            captures = ca.Group + 1;

                        break;
                    }
                    case Opcode.OpNumber.OP_JUMP:
                    {
                        var ju = (Jump)op;

                        ops.Add(new Regex.Op(ju.Number, ju.To));
                        break;
                    }
                    default:
                        throw new System.Exception(string.Format("Unhandled opcode {0:S} in regex generation", op.Number.ToString()));
                    }
                }
            }

            return new Regex(ops.ToArray(), targets.ToArray(),
                             exact.ToArray(), quantifiers.ToArray(),
                             captures);
        }

        public void AddMethod(int index, Subroutine sub)
        {
            var sg = new SubGenerator(this, Subroutines);
            var body = sg.Generate(sub, Subroutines[index].IsMain);

            MethodBuilder method_builder =
                ClassBuilder.DefineMethod(
                    Subroutines[index].MethodName,
                    MethodAttributes.Static|MethodAttributes.Public);
            body.CompileToMethod(method_builder,
                                 DebugInfoGenerator.CreatePdbGenerator());
        }

        public void AddInitMethod(FieldInfo main)
        {
            LabelTarget sub_label = Expression.Label(typeof(P5Code));
            MethodBuilder helper =
                ClassBuilder.DefineMethod(
                    "InitModule",
                    MethodAttributes.Public|MethodAttributes.Static,
                    typeof(void), new Type[] { typeof(Runtime) });
            Initializers.Add(Expression.Return(sub_label,
                                               Expression.Field(null, main),
                                               typeof(P5Code)));
            var constants_init =
                Expression.Lambda(
                    Expression.Label(
                        sub_label,
                        Expression.Block(Initializers)),
                        InitRuntime);

            constants_init.CompileToMethod(helper);
        }

        FieldInfo AddSubInitialization()
        {
            var code_ctor = typeof(P5Code).GetConstructor(
                new Type[] { typeof(P5Code.Sub), typeof(bool) });
            var get_method =
                typeof(Type).GetMethod(
                    "GetMethod", new Type[] { typeof(string) });
            var create_delegate =
                typeof(System.Delegate).GetMethod(
                    "CreateDelegate",
                    new Type[] { typeof(Type),
                                 typeof(MethodInfo) });
            var lexinfo_new_params = new Type[] {
                typeof(string), typeof(Opcode.Sigil), typeof(int),
                typeof(int), typeof(int), typeof(bool), typeof(bool),
            };
            var lexinfo_new = typeof(LexicalInfo).GetConstructor(lexinfo_new_params);
            var get_type =
                typeof(Type).GetMethod(
                    "GetType", new Type[] { typeof(string) });


            FieldInfo main = null;
            foreach (SubInfo si in Subroutines)
            {
                if (si.Subroutine.IsRegex)
                    continue;

                // new P5Code(System.Delegate.CreateDelegate(method, null)
                Expression initcode =
                    Expression.New(code_ctor, new Expression[] {
                            Expression.Call(
                                create_delegate,
                                Expression.Constant(typeof(P5Code.Sub)),
                                Expression.Call(
                                    Expression.Call(
                                        get_type,
                                        Expression.Constant(ClassBuilder.FullName)),
                                    get_method,
                                    Expression.Constant(si.MethodName))),
                            Expression.Constant(si.IsMain),
                        });

                Initializers.Add(
                    Expression.Assign(
                        Expression.Field(null, si.CodeField),
                        initcode));

                // code.ScratchPad = P5ScratchPad.CreateSubPad(lexicals,
                //                       main.ScratchPad)
                Expression[] alllex = new Expression[si.Lexicals.Length];
                for (int i = 0; i < alllex.Length; ++i)
                {
                    LexicalInfo lex = si.Lexicals[i];

                    alllex[i] = Expression.New(
                        lexinfo_new,
                        new Expression[] {
                            Expression.Constant(lex.Name),
                            Expression.Constant(lex.Slot),
                            Expression.Constant(lex.Level),
                            Expression.Constant(lex.Index),
                            Expression.Constant(lex.OuterIndex),
                            Expression.Constant(lex.InPad),
                            Expression.Constant(lex.FromMain),
                        });
                }
                Expression lexicals =
                    Expression.NewArrayInit(typeof(LexicalInfo), alllex);
                Expression init_pad =
                    Expression.Assign(
                        Expression.Property(
                            Expression.Field(null, si.CodeField),
                            "ScratchPad"),
                        Expression.Call(
                            typeof(P5ScratchPad).GetMethod("CreateSubPad"),
                            lexicals,
                            main != null ?
                            (Expression)Expression.Property(
                                    Expression.Field(null, main),
                                    "ScratchPad") :
                            (Expression)Expression.Constant(null, typeof(P5ScratchPad))));
                Initializers.Add(init_pad);

                if (si.IsMain)
                {
                    // code.NewScope(runtime);
                    Expression set_main_pad =
                        Expression.Call(
                            Expression.Field(null, si.CodeField),
                            typeof(P5Code).GetMethod("NewScope"),
                            InitRuntime);

                    Initializers.Add(set_main_pad);
                    main = si.CodeField;
                }
                else if (si.SubName == "BEGIN")
                {
                    Expression empty_list =
                        Expression.New(
                            typeof(P5List).GetConstructor(
                                new Type[] { typeof(Runtime) }),
                            InitRuntime);
                    Expression call_begin =
                        Expression.Call(
                            Expression.Field(null, si.CodeField),
                            typeof(P5Code).GetMethod("Call"),
                            InitRuntime,
                            Expression.Constant(Opcode.ContextValues.VOID),
                            empty_list);

                    Initializers.Add(call_begin);
                }
                else if (si.SubName != null)
                {
                    // runtime.SymbolTable.SetCode(runtime, sub_name, code)
                    Expression add_to_symboltable =
                        Expression.Call(
                            Expression.Field(
                                InitRuntime,
                                typeof(Runtime).GetField("SymbolTable")),
                            typeof(P5SymbolTable).GetMethod("SetCode"),
                            InitRuntime,
                            Expression.Constant(si.SubName),
                            Expression.Field(null, si.CodeField));
                    Initializers.Add(add_to_symboltable);
                }
            }

            return main;
        }

        public P5Code CompleteGeneration(Runtime runtime)
        {
            FieldInfo main = AddSubInitialization();
            AddInitMethod(main);

            Type mod = ClassBuilder.CreateType();
            object main_sub = mod.GetMethod("InitModule")
                                  .Invoke(null, new object[] { runtime });

            return (P5Code)main_sub;
        }

        private TypeBuilder ClassBuilder;
        private List<Expression> Initializers;
        private List<SubInfo> Subroutines;
        private int MethodIndex = 0;
        public ParameterExpression InitRuntime;
    }

    internal class SubGenerator
    {
        private static Type[] ProtoRuntime =
            new Type[] { typeof(Runtime) };
        private static Type[] ProtoRuntimeString =
            new Type[] { typeof(Runtime), typeof(string) };
        private static Type[] ProtoRuntimeInt =
            new Type[] { typeof(Runtime), typeof(int) };
        private static Type[] ProtoRuntimeBool =
            new Type[] { typeof(Runtime), typeof(bool) };
        private static Type[] ProtoRuntimeDouble =
            new Type[] { typeof(Runtime), typeof(double) };
        private static Type[] ProtoRuntimeIP5AnyArray =
            new Type[] { typeof(Runtime), typeof(IP5Any[]) };
        private static Type[] ProtoRuntimeP5Array =
            new Type[] { typeof(Runtime), typeof(P5Array) };
        private static Type[] ProtoRuntimeAny =
            new Type[] { typeof(Runtime), typeof(IP5Any) };
        private static Type[] ProtoStringString =
            new Type[] { typeof(string), typeof(string) };

        public SubGenerator(ModuleGenerator module_generator,
                            List<ModuleGenerator.SubInfo> subroutines)
        {
            Runtime = Expression.Parameter(typeof(Runtime), "runtime");
            Arguments = Expression.Parameter(typeof(P5Array), "args");
            Context = Expression.Parameter(typeof(Opcode.ContextValues), "context");
            Pad = Expression.Parameter(typeof(P5ScratchPad), "pad");
            Variables = new List<ParameterExpression>();
            Lexicals = new List<ParameterExpression>();
            Temporaries = new List<ParameterExpression>();
            BlockLabels = new List<LabelTarget>();
            Blocks = new List<Expression>();
            ValueBlocks = new Dictionary<int, Expression>();
            LexStates = new List<ParameterExpression>();
            RxStates = new List<ParameterExpression>();
            ModuleGenerator = module_generator;
            Subroutines = subroutines;
        }

        private Expression OpContext(Opcode op)
        {
            if (op.Context == (int)Opcode.ContextValues.CALLER)
                return Context;
            else
                return Expression.Constant(
                    (Opcode.ContextValues)op.Context,
                    typeof(Opcode.ContextValues));
        }

        private ParameterExpression GetVariable(int index, Type type)
        {
            if (typeof(P5Scalar).IsAssignableFrom(type))
                type = typeof(IP5Any);
            while (Variables.Count <= index)
                Variables.Add(null);
            if (Variables[index] == null)
                Variables[index] = Expression.Variable(type);

            return Variables[index];
        }

        private ParameterExpression GetVariable(int index)
        {
            return GetVariable(index, typeof(IP5Any));
        }

        private Type TypeForSlot(Opcode.Sigil slot)
        {
            return slot == Opcode.Sigil.SCALAR   ? typeof(P5Scalar) :
                   slot == Opcode.Sigil.ARRAY    ? typeof(P5Array) :
                   slot == Opcode.Sigil.HASH     ? typeof(P5Hash) :
                   slot == Opcode.Sigil.ITERATOR ? typeof(IEnumerator<IP5Any>) :
                                                   typeof(void);
        }

        private string MethodForSlot(Opcode.Sigil slot)
        {
            switch (slot)
            {
            case Opcode.Sigil.SCALAR:
                return "GetOrCreateScalar";
            case Opcode.Sigil.ARRAY:
                return "GetOrCreateArray";
            case Opcode.Sigil.HASH:
                return "GetOrCreateHash";
            case Opcode.Sigil.SUB:
                return "GetCode";
            case Opcode.Sigil.GLOB:
                return "GetOrCreateGlob";
            case Opcode.Sigil.HANDLE:
                return "GetOrCreateHandle";
            default:
                throw new System.Exception(string.Format("Unhandled slot {0:D}", slot));
            }
        }

        private string PropertyForSlot(Opcode.Sigil slot)
        {
            switch (slot)
            {
            case Opcode.Sigil.SCALAR:
                return "Scalar";
            case Opcode.Sigil.ARRAY:
                return "Array";
            case Opcode.Sigil.HASH:
                return "Hash";
            case Opcode.Sigil.SUB:
                return "Code";
            case Opcode.Sigil.HANDLE:
                return "Handle";
            default:
                throw new System.Exception(string.Format("Unhandled slot {0:D}", slot));
            }
        }

        private ParameterExpression GetTemporary(int index, Type type)
        {
            while (Temporaries.Count <= index)
                Temporaries.Add(null);
            if (Temporaries[index] == null)
            {
                if (type == null)
                    throw new System.Exception("Untyped temporary");
                Temporaries[index] =
                    Expression.Variable(type);
            }

            return Temporaries[index];
        }

        private ParameterExpression GetSavedLexState(int index)
        {
            while (LexStates.Count <= index)
                LexStates.Add(null);
            if (LexStates[index] == null)
            {
                LexStates[index] =
                    Expression.Variable(typeof(SavedLexState));
            }

            return LexStates[index];
        }

        private ParameterExpression GetSavedRxState(int index)
        {
            while (RxStates.Count <= index)
                RxStates.Add(null);
            if (RxStates[index] == null)
            {
                RxStates[index] =
                    Expression.Variable(typeof(RxResult));
            }

            return RxStates[index];
        }

        private ParameterExpression GetLexical(int index, Opcode.Sigil slot)
        {
            while (Lexicals.Count <= index)
                Lexicals.Add(null);
            if (Lexicals[index] == null)
                Lexicals[index] =
                    Expression.Variable(TypeForSlot(slot));

            return Lexicals[index];
        }

        private Expression GetLexicalPad(LexicalInfo info)
        {
            return GetLexicalPad(info, false);
        }

        private Expression GetLexicalPad(LexicalInfo info, bool writable)
        {
            var item =
                Expression.MakeIndex(
                    Pad, Pad.Type.GetProperty("Item"),
                    new Expression[] { Expression.Constant(info.Index) });

            if (writable)
                return item;
            else
                return Expression.Convert(item, TypeForSlot(info.Slot));
        }

        private Dictionary<int, bool> GeneratedScopes;

        public void GenerateScope(Subroutine sub, Scope scope)
        {
            if (scope.Outer != -1 && (scope.Flags & Scope.SCOPE_VALUE) == 0)
                GenerateScope(sub, sub.Scopes[scope.Outer]);
            if (GeneratedScopes.ContainsKey(scope.Id))
                return;
            GeneratedScopes.Add(scope.Id, true);

            int first_block = -1;
            for (int i = 0; i < sub.BasicBlocks.Length; ++i)
            {
                var block = sub.BasicBlocks[i];
                if (block.Scope != scope.Id)
                {
                    if (GeneratedScopes.ContainsKey(block.Scope))
                        continue;
                    bool is_inside = false;
                    for (int s = block.Scope; !is_inside && s != -1;
                         s = sub.Scopes[s].Outer)
                        is_inside = s == scope.Id;
                    if (is_inside)
                        GenerateScope(sub, sub.Scopes[block.Scope]);
                }
                else
                {
                    List<Expression> exps = new List<Expression>();

                    if ((scope.Flags & Scope.SCOPE_EVAL) != 0)
                    {
                        exps.Add(
                            Expression.Call(
                                Expression.Field(Runtime, "CallStack"),
                                typeof(Stack<StackFrame>).GetMethod("Push"),
                                Expression.New(
                                    typeof(StackFrame).GetConstructor(new Type[] {
                                            typeof(string), typeof(string),
                                            typeof(int), typeof(P5Code),
                                            typeof(Opcode.ContextValues),
                                            typeof(bool)}),
                                    Expression.Constant(sub.LexicalStates[scope.LexicalState].Package),
                                    Expression.Constant(scope.Start.File),
                                    Expression.Constant(scope.Start.Line),
                                    Expression.Constant(null, typeof(P5Code)),
                                    Expression.Constant((Opcode.ContextValues)scope.Context),
                                    Expression.Constant(true)
                                    )));
                    }
                    // TODO should not rely on block order
                    if (first_block == -1)
                        first_block = i;

                    Generate(sub, block, exps);

                    Expression body = null;

                    if ((scope.Flags & Scope.SCOPE_EVAL) != 0)
                    {
                        var except = new List<Expression>();
                        var ex = Expression.Variable(typeof(System.Exception));
                        for (int j = scope.Opcodes.Length - 1; j >= 0; --j)
                            Generate(sub, scope.Opcodes[j], except);
                        except.Add(
                            Expression.Call(
                                Runtime,
                                typeof(Runtime).GetMethod("SetException"),
                                ex));
                        except.Add(
                            Expression.New(
                                typeof(P5Scalar).GetConstructor(ProtoRuntime),
                                Runtime));

                        body = Expression.Block(
                            typeof(IP5Any),
                            Expression.Label(BlockLabels[i]),
                            Expression.TryCatchFinally(
                                Expression.Block(typeof(IP5Any), exps),
                                Expression.Call(
                                    Expression.Field(Runtime, "CallStack"),
                                    typeof(Stack<StackFrame>).GetMethod("Pop")),
                                Expression.Catch(
                                    ex,
                                    Expression.Block(typeof(IP5Any), except))
                                ));
                    }
                    else if (scope.Opcodes.Length > 0)
                    {
                        var fault = new List<Expression>();
                        for (int j = scope.Opcodes.Length - 1; j >= 0; --j)
                            Generate(sub, scope.Opcodes[j], fault);

                        body = Expression.Block(
                            typeof(IP5Any),
                            Expression.Label(BlockLabels[i]),
                            Expression.TryFault(
                                Expression.Block(typeof(IP5Any), exps),
                                Expression.Block(typeof(void), fault)));
                    }
                    else
                    {
                        exps.Insert(0, Expression.Label(BlockLabels[i]));
                        body = Expression.Block(typeof(IP5Any), exps);
                    }

                    if ((scope.Flags & Scope.SCOPE_VALUE) != 0)
                        ValueBlocks[first_block] = body;
                    else
                        Blocks.Add(body);
                }
            }
        }

        public LambdaExpression Generate(Subroutine sub, bool is_main)
        {
            GeneratedScopes = new Dictionary<int, bool>();
            IsMain = is_main;
            SubLabel = Expression.Label(typeof(IP5Any));

            for (int i = 0; i < sub.BasicBlocks.Length; ++i)
                BlockLabels.Add(Expression.Label("L" + i.ToString()));
            for (int i = 0; i < sub.Scopes.Length; ++i)
                if ((sub.Scopes[i].Flags & Scope.SCOPE_VALUE) != 0)
                    GenerateScope(sub, sub.Scopes[i]);
            GenerateScope(sub, sub.Scopes[0]);

            // remove the dummy entry for @_ if present
            if (Lexicals.Count > 0 && Lexicals[0] == null)
                Lexicals.RemoveAt(0);
            if (Lexicals.Count != 0)
            {
                List<Expression> init_exps = new List<Expression>();
                foreach (var lex in Lexicals)
                {
                    init_exps.Add(
                        Expression.Assign(
                            lex,
                            Expression.New(
                                lex.Type.GetConstructor(ProtoRuntime),
                                Runtime)));
                }
                Blocks.Insert(0, Expression.Block(typeof(void), init_exps));
            }

            var vars = new List<ParameterExpression>();
            AddVars(vars, Variables);
            AddVars(vars, Lexicals);
            AddVars(vars, Temporaries);
            AddVars(vars, LexStates);
            AddVars(vars, RxStates);

            var block = Expression.Block(typeof(IP5Any), vars, Blocks);
            var args = new ParameterExpression[] { Runtime, Context, Pad, Arguments };
            return Expression.Lambda<P5Code.Sub>(Expression.Label(SubLabel, block), args);
        }

        private void AddVars(List<ParameterExpression> vars,
                             List<ParameterExpression> toAdd)
        {
            foreach (var i in toAdd)
                if (i != null)
                    vars.Add(i);
        }

        public void UpdateFileLine(Opcode op, List<Expression> expressions)
        {
            expressions.Add(
                Expression.Assign(
                    Expression.Field(Runtime, "File"),
                    Expression.Constant(op.Position.File)));
            expressions.Add(
                Expression.Assign(
                    Expression.Field(Runtime, "Line"),
                    Expression.Constant(op.Position.Line)));
        }

        public void Generate(Subroutine sub, BasicBlock bb,
                             List<Expression> expressions)
        {
            foreach (var o in bb.Opcodes)
            {
                if (o.Position.File != null)
                    UpdateFileLine(o, expressions);
                expressions.Add(Generate(sub, o));
            }
        }

        public void Generate(Subroutine sub, Opcode[] ops,
                             List<Expression> expressions)
        {
            foreach (var o in ops)
            {
                if (o.Position.File != null)
                    UpdateFileLine(o, expressions);
                expressions.Add(Generate(sub, o));
            }
        }

        public Expression GenerateJump(Subroutine sub, Opcode op,
                                       string method, ExpressionType type)
        {
            var ju = (Jump)op;

            Expression cmp = Expression.MakeBinary(
                type,
                Expression.Call(
                    Generate(sub, ju.Childs[0]),
                    typeof(IP5Any).GetMethod(method), Runtime),
                Expression.Call(
                    Generate(sub, ju.Childs[1]),
                    typeof(IP5Any).GetMethod(method), Runtime));
            Expression jump = Expression.Goto(
                BlockLabels[ju.To],
                typeof(IP5Any));

            return Expression.IfThen(cmp, jump);
        }

        public Expression Generate(Subroutine sub, Opcode op)
        {
            switch(op.Number)
            {
            case Opcode.OpNumber.OP_FRESH_STRING:
            case Opcode.OpNumber.OP_CONSTANT_STRING:
            {
                var cs = (ConstantString)op;

                return
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(ProtoRuntimeString),
                        new Expression[] {
                            Runtime,
                            Expression.Constant(cs.Value) });
            }
            case Opcode.OpNumber.OP_CONSTANT_UNDEF:
            {
                var ctor = typeof(P5Scalar).GetConstructor(ProtoRuntime);

                return Expression.New(ctor, new Expression[] { Runtime });
            }
            case Opcode.OpNumber.OP_CONSTANT_INTEGER:
            {
                var ctor = typeof(P5Scalar).GetConstructor(ProtoRuntimeInt);
                var ci = (ConstantInt)op;
                var init =
                    Expression.New(ctor,
                                   new Expression[] {
                                       ModuleGenerator.InitRuntime,
                                       Expression.Constant(ci.Value) });
                FieldInfo field = ModuleGenerator.AddField(init);

                return Expression.Field(null, field);
            }
            case Opcode.OpNumber.OP_CONSTANT_FLOAT:
            {
                var ctor = typeof(P5Scalar).GetConstructor(ProtoRuntimeDouble);
                var cf = (ConstantFloat)op;
                var init =
                    Expression.New(ctor,
                                   new Expression[] {
                                       ModuleGenerator.InitRuntime,
                                       Expression.Constant(cf.Value) });
                FieldInfo field = ModuleGenerator.AddField(init);

                return Expression.Field(null, field);
            }
            case Opcode.OpNumber.OP_CONSTANT_SUB:
            {
                ConstantSub cs = (ConstantSub)op;

                return Expression.Field(null, Subroutines[cs.Value].CodeField);
            }
            case Opcode.OpNumber.OP_GLOBAL:
            {
                Global gop = (Global)op;
                var st = typeof(Runtime).GetField("SymbolTable");
                string name = MethodForSlot(gop.Slot);
                return
                    Expression.Call(
                        Expression.Field(Runtime, st),
                        typeof(P5SymbolTable).GetMethod(name),
                        Runtime,
                        Expression.Constant(gop.Name));
            }
            case Opcode.OpNumber.OP_GLOB_SLOT:
            {
                GlobSlot gop = (GlobSlot)op;
                string name = PropertyForSlot(gop.Slot);
                return
                    Expression.Property(
                        Expression.Convert(
                            Generate(sub, op.Childs[0]),
                            typeof(P5Typeglob)),
                        name);
            }
            case Opcode.OpNumber.OP_GLOB_SLOT_SET:
            {
                GlobSlot gop = (GlobSlot)op;
                string name = PropertyForSlot(gop.Slot);
                var property =
                    Expression.Property(
                        Expression.Convert(
                            Generate(sub, op.Childs[0]),
                            typeof(P5Typeglob)),
                        name);

                return
                    Expression.Assign(
                        property,
                        Expression.Convert(
                            Generate(sub, op.Childs[1]),
                            property.Type));
            }
            case Opcode.OpNumber.OP_MAKE_LIST:
            {
                List<Expression> data = new List<Expression>();
                foreach (var i in op.Childs)
                    data.Add(Generate(sub, i));
                return
                    Expression.New(
                        typeof(P5List).GetConstructor(ProtoRuntimeIP5AnyArray),
                        new Expression[] {
                            Runtime,
                            Expression.NewArrayInit(typeof(IP5Any), data) });
            }
            case Opcode.OpNumber.OP_ANONYMOUS_ARRAY:
            {
                return
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(
                            new Type[] { typeof(Runtime),
                                         typeof(IP5Referrable) }),
                        Runtime,
                        Expression.New(
                            typeof(P5Array).GetConstructor(ProtoRuntimeP5Array),
                            Runtime,
                            Generate(sub, op.Childs[0])));
            }
            case Opcode.OpNumber.OP_ANONYMOUS_HASH:
            {
                return
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(
                            new Type[] { typeof(Runtime),
                                         typeof(IP5Referrable) }),
                        Runtime,
                        Expression.New(
                            typeof(P5Hash).GetConstructor(ProtoRuntimeP5Array),
                            Runtime,
                            Generate(sub, op.Childs[0])));
            }
            case Opcode.OpNumber.OP_PRINT:
            {
                return
                    Expression.Call(
                        typeof(Builtins).GetMethod("Print"),
                        Runtime,
                        Expression.Convert(
                            Generate(sub, op.Childs[0]),
                            typeof(P5Handle)),
                        Expression.Convert(
                            Generate(sub, op.Childs[1]),
                            typeof(P5List)));
            }
            case Opcode.OpNumber.OP_END:
            {
                return
                    Expression.Return(
                        SubLabel,
                        Expression.Constant(null, typeof(IP5Any)),
                        typeof(IP5Any));
            }
            case Opcode.OpNumber.OP_STOP:
            {
                // TODO remove STOP
                return Generate(sub, op.Childs[0]);
            }
            case Opcode.OpNumber.OP_DIE:
            {
                return Expression.Throw(
                    Expression.New(
                        typeof(P5Exception).GetConstructor(ProtoRuntimeAny),
                        Runtime,
                        Generate(sub, op.Childs[0])));
            }
            case Opcode.OpNumber.OP_DO_FILE:
            {
                return
                    Expression.Call(
                        typeof(Builtins).GetMethod("DoFile"),
                        Runtime,
                        OpContext(op),
                        Generate(sub, op.Childs[0]));
            }
            case Opcode.OpNumber.OP_REQUIRE_FILE:
            {
                return
                    Expression.Call(
                        typeof(Builtins).GetMethod("RequireFile"),
                        Runtime,
                        OpContext(op),
                        Generate(sub, op.Childs[0]));
            }
            case Opcode.OpNumber.OP_WANTARRAY:
            {
                return
                    Expression.Call(
                        typeof(Builtins).GetMethod("WantArray"),
                        Runtime,
                        Context);
            }
            case Opcode.OpNumber.OP_RETURN:
            {
                Expression empty =
                    Expression.New(typeof(P5List).GetConstructor(ProtoRuntime), Runtime);
                if (op.Childs.Length == 0)
                {
                    return Expression.Return(SubLabel, empty, typeof(IP5Any));
                }
                else
                {
                    ParameterExpression val = Expression.Variable(typeof(IP5Any), "ret");
                    Expression iflist =
                        Expression.Condition(
                            Expression.Equal(
                                Context,
                                Expression.Constant(Opcode.ContextValues.LIST)),
                            val, empty, typeof(IP5Any));
                    Expression retscalar =
                        Expression.Call(
                            val,
                            typeof(IP5Any).GetMethod("AsScalar"),
                            Runtime);
                    Expression ifscalar =
                        Expression.Condition(
                            Expression.Equal(
                                Context,
                                Expression.Constant(Opcode.ContextValues.SCALAR)),
                            retscalar, iflist, typeof(IP5Any));

                    return
                        Expression.Return(
                            SubLabel,
                            Expression.Block(
                                typeof(IP5Any), new ParameterExpression[] { val },
                                new Expression[] {
                                    Expression.Assign(
                                        val,
                                        Generate(sub, op.Childs[0])),
                                    ifscalar }),
                            typeof(IP5Any));
                }
            }
            case Opcode.OpNumber.OP_ASSIGN:
            {
                return
                    Expression.Call(
                        Generate(sub, op.Childs[0]),
                        typeof(IP5Any).GetMethod("Assign"), Runtime,
                        Generate(sub, op.Childs[1]));
            }
            case Opcode.OpNumber.OP_GET:
            {
                return GetVariable(((GetSet)op).Index);
            }
            case Opcode.OpNumber.OP_SET:
            {
                var e = Generate(sub, op.Childs[0]);

                // temporary workaround for the fact that not all
                // variables can be of type IP5Any, will need to add
                // type information to get/set opcodes, as it is done
                // for temporaries
                return Expression.Assign(
                    GetVariable(((GetSet)op).Index, e.Type),
                    e);
            }
            case Opcode.OpNumber.OP_JUMP:
            {
                return Expression.Goto(BlockLabels[((Jump)op).To], typeof(IP5Any));
            }
            case Opcode.OpNumber.OP_JUMP_IF_NULL:
            {
                Expression cmp = Expression.Equal(
                    Generate(sub, op.Childs[0]),
                    Expression.Constant(null, typeof(object)));
                Expression jump = Expression.Goto(
                    BlockLabels[((Jump)op).To],
                    typeof(IP5Any));

                return Expression.IfThen(cmp, jump);
            }
            case Opcode.OpNumber.OP_JUMP_IF_S_EQ:
            {
                return GenerateJump(sub, op, "AsString",
                                    ExpressionType.Equal);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_EQ:
            {
                return GenerateJump(sub, op, "AsFloat",
                                    ExpressionType.Equal);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_GE:
            {
                return GenerateJump(sub, op, "AsFloat",
                                    ExpressionType.GreaterThanOrEqual);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_LE:
            {
                return GenerateJump(sub, op, "AsFloat",
                                    ExpressionType.LessThanOrEqual);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_GT:
            {
                return GenerateJump(sub, op, "AsFloat",
                                    ExpressionType.GreaterThan);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_LT:
            {
                return GenerateJump(sub, op, "AsFloat",
                                    ExpressionType.LessThan);
            }
            case Opcode.OpNumber.OP_JUMP_IF_TRUE:
            {
                Expression cmp = Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("AsBoolean"),
                    Runtime);
                Expression jump = Expression.Goto(
                    BlockLabels[((Jump)op).To],
                    typeof(IP5Any));

                return Expression.IfThen(cmp, jump);
            }
            case Opcode.OpNumber.OP_LOG_NOT:
            {
                return Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeBool),
                    Runtime,
                    Expression.Not(
                        Expression.Call(
                            Generate(sub, op.Childs[0]),
                            typeof(IP5Any).GetMethod("AsBoolean"),
                            Runtime)));
            }
            case Opcode.OpNumber.OP_MINUS:
            {
                return Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeInt),
                    Runtime,
                    Expression.Negate(
                        Expression.Call(
                            Generate(sub, op.Childs[0]),
                            typeof(IP5Any).GetMethod("AsInteger"),
                            Runtime)));
            }
            case Opcode.OpNumber.OP_DEFINED:
            {
                return
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(ProtoRuntimeBool),
                        Runtime,
                        Expression.Call(Generate(sub, op.Childs[0]),
                                        typeof(IP5Any).GetMethod("IsDefined"),
                                        Runtime));
            }
            case Opcode.OpNumber.OP_CONCATENATE:
            {
                Expression s1 =
                    Expression.Call(Generate(sub, op.Childs[0]),
                                    typeof(IP5Any).GetMethod("AsString"),
                                    Runtime);
                Expression s2 =
                    Expression.Call(Generate(sub, op.Childs[1]),
                                    typeof(IP5Any).GetMethod("AsString"),
                                    Runtime);
                return
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(ProtoRuntimeString),
                        Runtime,
                        Expression.Call(
                            typeof(string).GetMethod("Concat", ProtoStringString), s1, s2));
            }
            case Opcode.OpNumber.OP_CONCATENATE_ASSIGN:
            {
                return Expression.Call(
                    Expression.Convert(
                        Generate(sub, op.Childs[0]),
                        typeof(P5Scalar)),
                    typeof(IP5Any).GetMethod("ConcatAssign"),
                    Runtime,
                    Generate(sub, op.Childs[1]));
            }
            case Opcode.OpNumber.OP_ARRAY_LENGTH:
            {
                Expression len =
                    Expression.Call(
                        Expression.Convert(
                            Generate(sub, op.Childs[0]),
                            typeof(P5Array)),
                        typeof(P5Array).GetMethod("GetCount"),
                        Runtime);
                Expression len_1 = Expression.Subtract(len, Expression.Constant(1));
                return Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeInt),
                    new Expression[] { Runtime, len_1 });
            }
            case Opcode.OpNumber.OP_ADD:
            {
                Expression sum =
                    Expression.Add(
                        Expression.Call(
                            Generate(sub, op.Childs[0]),
                            typeof(IP5Any).GetMethod("AsFloat"), Runtime),
                        Expression.Call(
                            Generate(sub, op.Childs[1]),
                            typeof(IP5Any).GetMethod("AsFloat"), Runtime));
                return Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeDouble),
                    new Expression[] { Runtime, sum });
            }
            case Opcode.OpNumber.OP_SUBTRACT:
            {
                Expression sum =
                    Expression.Subtract(
                        Expression.Call(
                            Generate(sub, op.Childs[0]),
                            typeof(IP5Any).GetMethod("AsFloat"), Runtime),
                        Expression.Call(
                            Generate(sub, op.Childs[1]),
                            typeof(IP5Any).GetMethod("AsFloat"), Runtime));
                return Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeDouble),
                    new Expression[] { Runtime, sum });
            }
            case Opcode.OpNumber.OP_MULTIPLY:
            {
                Expression sum =
                    Expression.Multiply(
                        Expression.Call(
                            Generate(sub, op.Childs[0]),
                            typeof(IP5Any).GetMethod("AsFloat"), Runtime),
                        Expression.Call(
                            Generate(sub, op.Childs[1]),
                            typeof(IP5Any).GetMethod("AsFloat"), Runtime));
                return Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeDouble),
                    new Expression[] { Runtime, sum });
            }
            case Opcode.OpNumber.OP_PREINC:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Scalar).GetMethod("PreIncrement"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_PREDEC:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Scalar).GetMethod("PreDecrement"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_POSTINC:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Scalar).GetMethod("PostIncrement"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_POSTDEC:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Scalar).GetMethod("PostDecrement"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_ARRAY_ELEMENT:
            {
                var ea = (ElementAccess)op;

                return Expression.Call(
                    Generate(sub, op.Childs[1]),
                    typeof(P5Array).GetMethod("GetItemOrUndef"),
                    Runtime,
                    Generate(sub, op.Childs[0]),
                    Expression.Constant(ea.Create != 0));
            }
            case Opcode.OpNumber.OP_HASH_ELEMENT:
            {
                var ea = (ElementAccess)op;

                return Expression.Call(
                    Generate(sub, op.Childs[1]),
                    typeof(P5Hash).GetMethod("GetItemOrUndef"),
                    Runtime,
                    Generate(sub, op.Childs[0]),
                    Expression.Constant(ea.Create != 0));
            }
            case Opcode.OpNumber.OP_EXISTS_ARRAY:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[1]),
                    typeof(P5Array).GetMethod("Exists"),
                    Runtime,
                    Generate(sub, op.Childs[0]));
            }
            case Opcode.OpNumber.OP_EXISTS_HASH:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[1]),
                    typeof(P5Hash).GetMethod("Exists"),
                    Runtime,
                    Generate(sub, op.Childs[0]));
            }
            case Opcode.OpNumber.OP_ARRAY_PUSH:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Array).GetMethod("PushList"),
                    Runtime,
                    Generate(sub, op.Childs[1]));
            }
            case Opcode.OpNumber.OP_ARRAY_UNSHIFT:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Array).GetMethod("UnshiftList"),
                    Runtime,
                    Generate(sub, op.Childs[1]));
            }
            case Opcode.OpNumber.OP_ARRAY_POP:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Array).GetMethod("PopElement"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_ARRAY_SHIFT:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Array).GetMethod("ShiftElement"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_ITERATOR:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Array).GetMethod("GetEnumerator", ProtoRuntime),
                    Runtime);
            }
            case Opcode.OpNumber.OP_ITERATOR_NEXT:
            {
                Expression iter = Generate(sub, op.Childs[0]);
                Expression has_next =
                    Expression.Call(
                        iter, typeof(IEnumerator).GetMethod("MoveNext"));

                return Expression.Condition(
                    has_next,
                    Expression.Property(iter, "Current"),
                    Expression.Constant(null, typeof(IP5Any)));
            }
            case Opcode.OpNumber.OP_ARRAY_SLICE:
            {
                var ea = (ElementAccess)op;

                return Expression.Call(
                    Generate(sub, op.Childs[1]),
                    typeof(P5Array).GetMethod("Slice"),
                    Runtime,
                    Generate(sub, op.Childs[0]),
                    Expression.Constant(ea.Create != 0));
            }
            case Opcode.OpNumber.OP_HASH_SLICE:
            {
                var ea = (ElementAccess)op;

                return Expression.Call(
                    Generate(sub, op.Childs[1]),
                    typeof(P5Hash).GetMethod("Slice"),
                    Runtime,
                    Generate(sub, op.Childs[0]),
                    Expression.Constant(ea.Create != 0));
            }
            case Opcode.OpNumber.OP_LIST_SLICE:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[1]),
                    typeof(P5List).GetMethod("Slice", new Type[] {
                            typeof(Runtime), typeof(P5Array) }),
                    Runtime,
                    Generate(sub, op.Childs[0]));
            }
            case Opcode.OpNumber.OP_TEMPORARY:
            {
                Temporary tm = (Temporary)op;

                return GetTemporary(tm.Index, TypeForSlot(tm.Slot));
            }
            case Opcode.OpNumber.OP_TEMPORARY_SET:
            {
                Temporary tm = (Temporary)op;
                Expression exp = Generate(sub, op.Childs[0]);

                return Expression.Assign(GetTemporary(tm.Index, exp.Type), exp);
            }
            case Opcode.OpNumber.OP_LEXICAL:
            {
                Lexical lx = (Lexical)op;

                return lx.Index == 0 && !IsMain ? Arguments : GetLexical(lx.Index, lx.Slot);
            }
            case Opcode.OpNumber.OP_LEXICAL_CLEAR:
            {
                Lexical lx = (Lexical)op;
                Expression lexvar = GetLexical(lx.Index, lx.Slot);

                return Expression.Assign(lexvar, Expression.Constant(null, lexvar.Type));
            }
            case Opcode.OpNumber.OP_LEXICAL_SET:
            {
                Lexical lx = (Lexical)op;
                Expression lexvar = GetLexical(lx.Index, lx.Slot);

                return Expression.Assign(
                    lexvar,
                    Expression.Convert(Generate(sub, op.Childs[0]), lexvar.Type));
            }
            case Opcode.OpNumber.OP_LEXICAL_PAD:
            {
                Lexical lx = (Lexical)op;

                return GetLexicalPad(lx.LexicalInfo);
            }
            case Opcode.OpNumber.OP_LEXICAL_PAD_CLEAR:
            {
                Lexical lx = (Lexical)op;
                Expression lexvar = GetLexicalPad(lx.LexicalInfo, true);

                return Expression.Assign(lexvar, Expression.Constant(null, lexvar.Type));
            }
            case Opcode.OpNumber.OP_BLESS:
            {
                return
                    Expression.Call(
                        typeof(Builtins).GetMethod("Bless"),
                        Runtime,
                        Generate(sub, op.Childs[0]),
                        Generate(sub, op.Childs[1]));
            }
            case Opcode.OpNumber.OP_CALL_METHOD:
            {
                CallMethod cm = (CallMethod)op;

                return
                    Expression.Call(
                        Generate(sub, op.Childs[0]),
                        typeof(P5List).GetMethod("CallMethod"),
                        Runtime, OpContext(op),
                        Expression.Constant(cm.Method));
            }
            case Opcode.OpNumber.OP_FIND_METHOD:
            {
                CallMethod cm = (CallMethod)op;

                return
                    Expression.Call(
                        Generate(sub, op.Childs[0]),
                        typeof(IP5Any).GetMethod("FindMethod"),
                        Runtime, Expression.Constant(cm.Method));
            }
            case Opcode.OpNumber.OP_CALL:
            {
                return
                    Expression.Call(
                        Generate(sub, op.Childs[1]), typeof(P5Code).GetMethod("Call"),
                        Runtime, OpContext(op), Generate(sub, op.Childs[0]));
            }
            case Opcode.OpNumber.OP_REFTYPE:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("ReferenceType"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_REFERENCE:
            {
                return Expression.New(
                    typeof(P5Scalar).GetConstructor(
                        new Type[] { typeof(Runtime), typeof(IP5Referrable) }),
                    new Expression[] { Runtime, Generate(sub, op.Childs[0]) });
            }
            case Opcode.OpNumber.OP_VIVIFY_SCALAR:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("VivifyScalar"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_VIVIFY_ARRAY:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("VivifyArray"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_VIVIFY_HASH:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("VivifyHash"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_DEREFERENCE_SCALAR:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("DereferenceScalar"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_DEREFERENCE_ARRAY:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("DereferenceArray"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_DEREFERENCE_HASH:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("DereferenceHash"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_DEREFERENCE_GLOB:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("DereferenceGlob"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_DEREFERENCE_SUB:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(IP5Any).GetMethod("DereferenceSubroutine"),
                    Runtime);
            }
            case Opcode.OpNumber.OP_MAKE_CLOSURE:
            {
                return Expression.Call(
                    Generate(sub, op.Childs[0]),
                    typeof(P5Code).GetMethod("MakeClosure"),
                    Runtime, Pad);
            }
            case Opcode.OpNumber.OP_LOCALIZE_GLOB_SLOT:
            {
                var exps = new List<Expression>();
                var vars = new List<ParameterExpression>();
                var lop = (LocalGlobSlot)op;
                var st = typeof(Runtime).GetField("SymbolTable");
                var glob = Expression.Variable(typeof(P5Typeglob));
                var saved = Expression.Variable(TypeForSlot(lop.Slot));
                var temp = GetTemporary(lop.Index, typeof(IP5Any));

                // FIXME do not walk twice the symbol table
                exps.Add(
                    Expression.Assign(
                        glob,
                        Expression.Call(
                            Expression.Field(Runtime, st),
                            typeof(P5SymbolTable).GetMethod("GetOrCreateGlob"),
                            Runtime,
                            Expression.Constant(lop.Name))));
                exps.Add(
                    Expression.Assign(
                        temp,
                        Expression.Call(
                            Expression.Field(Runtime, st),
                            typeof(P5SymbolTable).GetMethod(MethodForSlot(lop.Slot)),
                            Runtime,
                            Expression.Constant(lop.Name))));
                exps.Add(
                    Expression.Assign(
                        saved,
                        Expression.Convert(
                            Expression.Call(
                                temp,
                                typeof(IP5Any).GetMethod("Localize"),
                                Runtime),
                            saved.Type)));
                exps.Add(
                    Expression.Assign(
                        Expression.Property(
                            glob,
                            PropertyForSlot(lop.Slot)),
                        saved));
                exps.Add(saved);

                vars.Add(glob);
                vars.Add(saved);

                return Expression.Block(typeof(IP5Any), vars, exps);
            }
            case Opcode.OpNumber.OP_RESTORE_GLOB_SLOT:
            {
                var exps = new List<Expression>();
                var vars = new List<ParameterExpression>();
                var lop = (LocalGlobSlot)op;
                var st = typeof(Runtime).GetField("SymbolTable");
                var glob = Expression.Variable(typeof(P5Typeglob));
                var saved = GetTemporary(lop.Index, typeof(IP5Any));

                exps.Add(
                    Expression.Assign(
                        glob,
                        Expression.Call(
                            Expression.Field(Runtime, st),
                            typeof(P5SymbolTable).GetMethod("GetOrCreateGlob"),
                            Runtime,
                            Expression.Constant(lop.Name))));
                exps.Add(
                    Expression.Assign(
                        Expression.Property(
                            glob,
                            PropertyForSlot(lop.Slot)),
                        Expression.Convert(
                            saved,
                            TypeForSlot(lop.Slot))));
                exps.Add(
                    Expression.Assign(
                        saved,
                        Expression.Constant(null, saved.Type)));

                vars.Add(glob);

                return Expression.IfThen(
                    Expression.NotEqual(
                        saved,
                        Expression.Constant(null, typeof(IP5Any))),
                    Expression.Block(typeof(IP5Any), vars, exps));
            }
            case Opcode.OpNumber.OP_LEXICAL_STATE_SET:
            {
                var ls = (LexState)op;
                var state = sub.LexicalStates[ls.Index];

                return Expression.Block(
                    typeof(void),
                    Expression.Assign(
                        Expression.Field(Runtime, "Package"),
                        Expression.Constant(state.Package)),
                    Expression.Assign(
                        Expression.Field(Runtime, "Hints"),
                        Expression.Constant(state.Hints)));
            }
            case Opcode.OpNumber.OP_LEXICAL_STATE_SAVE:
            {
                var ls = (LexState)op;
                var slot = GetSavedLexState(ls.Index);

                return Expression.Block(
                    typeof(void),
                    Expression.Assign(
                        Expression.Field(slot, "Package"),
                        Expression.Field(Runtime, "Package")),
                    Expression.Assign(
                        Expression.Field(slot, "Hints"),
                        Expression.Field(Runtime, "Hints")));
            }
            case Opcode.OpNumber.OP_LEXICAL_STATE_RESTORE:
            {
                var ls = (LexState)op;
                var slot = GetSavedLexState(ls.Index);

                return Expression.Block(
                    typeof(void),
                    Expression.Assign(
                        Expression.Field(Runtime, "Package"),
                        Expression.Field(slot, "Package")),
                    Expression.Assign(
                        Expression.Field(Runtime, "Hints"),
                        Expression.Field(slot, "Hints")));
            }
            case Opcode.OpNumber.OP_CALLER:
            {
                return op.Childs.Length == 0 ?
                    Expression.Call(
                        Runtime,
                        typeof(Runtime).GetMethod("CallerNoArg"),
                        OpContext(op)) :
                    Expression.Call(
                        Runtime,
                        typeof(Runtime).GetMethod("CallerWithArg"),
                        Generate(sub, op.Childs[0]),
                        OpContext(op));
            }
            case Opcode.OpNumber.OP_CONSTANT_REGEX:
            {
                ConstantSub cs = (ConstantSub)op;

                return Expression.Field(null, Subroutines[cs.Value].CodeField);
            }
            case Opcode.OpNumber.OP_POS:
            {
                return Expression.New(
                    typeof(P5Pos).GetConstructor(ProtoRuntimeAny),
                    Runtime,
                    Generate(sub, op.Childs[0]));
            }
            case Opcode.OpNumber.OP_RX_STATE_RESTORE:
            {
                RegexState rs = (RegexState)op;

                return Expression.Assign(
                    Expression.Field(Runtime, "LastMatch"),
                    GetSavedRxState(rs.Index));
            }
            case Opcode.OpNumber.OP_MATCH:
            {
                RegexMatch rm = (RegexMatch)op;
                bool global = (rm.Flags & Opcode.RX_GLOBAL) != 0;
                var meth = typeof(Regex).GetMethod(global ? "MatchGlobal" : "Match");

                return
                    Expression.Call(
                        Generate(sub, op.Childs[1]),
                        meth,
                        Runtime,
                        Generate(sub, op.Childs[0]),
                        Expression.Constant(rm.Flags & Opcode.RX_KEEP),
                        OpContext(rm),
                        GetSavedRxState(rm.Index));
            }
            case Opcode.OpNumber.OP_REPLACE:
            {
                RegexMatch rm = (RegexMatch)op;
                bool global = (rm.Flags & Opcode.RX_GLOBAL) != 0;

                if (global)
                    return GenerateGlobalSubstitution(sub, rm);
                else
                    return GenerateSubstitution(sub, rm);
            }
            default:
                throw new System.Exception(string.Format("Unhandled opcode {0:S} in generation", op.Number.ToString()));
            }
        }

        private Expression GenerateGlobalSubstitution(Subroutine sub, RegexMatch rm)
        {
            var scalar = Expression.Variable(typeof(P5Scalar));
            var init_scalar =
                Expression.Assign(scalar, Generate(sub, rm.Childs[0]));
            var pos = Expression.Variable(typeof(int));
            var count = Expression.Variable(typeof(int));
            var matched = Expression.Variable(typeof(bool));
            var str = Expression.Variable(typeof(string));
            var replace = Expression.Variable(typeof(string));
            var repl_list = Expression.Variable(typeof(List<RxReplacement>));
            var init_str =
                Expression.Assign(
                    str,
                    Expression.Call(
                        scalar,
                        typeof(IP5Any).GetMethod("AsString"),
                        Runtime));
            var match = Expression.Call(
                Generate(sub, rm.Childs[1]),
                typeof(Regex).GetMethod("MatchString"),
                Runtime,
                str,
                pos,
                GetSavedRxState(rm.Index));
            var rxstate = Expression.Field(
                Runtime,
                typeof(Runtime).GetField("LastMatch"));
            var rx_end =
                Expression.Field(
                    rxstate,
                    typeof(RxResult).GetField("End"));
            var rx_start =
                Expression.Field(
                    rxstate,
                    typeof(RxResult).GetField("Start"));

            var if_match = new List<Expression>();

            if_match.Add(Expression.PreIncrementAssign(count));
            if_match.Add(Expression.Assign(matched, Expression.Constant(true)));
            if_match.Add(Expression.Assign(pos, rx_end));

            // at this point all nested scopes have been generated
            if_match.Add(Expression.Assign(
                             replace,
                             Expression.Call(
                                 ValueBlocks[rm.To],
                                 typeof(IP5Any).GetMethod("AsString"),
                                 Runtime)));

            if_match.Add(
                Expression.Call(
                    repl_list,
                    typeof(List<RxReplacement>).GetMethod("Add"),
                    Expression.New(
                        typeof(RxReplacement).GetConstructor(
                            new Type[] { typeof(string), typeof(int), typeof(int) }),
                        replace, rx_start, rx_end)));

            var break_to = Expression.Label(typeof(void));
            var loop =
                Expression.Loop(
                    Expression.Block(
                        Expression.IfThenElse(
                            match,
                            Expression.Block(typeof(void), if_match),
                            Expression.Break(break_to))),
                    break_to);

            // TODO save last match

            var vars = new List<ParameterExpression>();
            vars.Add(scalar);
            vars.Add(pos);
            vars.Add(count);
            vars.Add(matched);
            vars.Add(str);
            vars.Add(replace);
            vars.Add(repl_list);

            var body = new List<Expression>();
            body.Add(init_scalar);
            body.Add(init_str);
            body.Add(Expression.Assign(pos, Expression.Constant(-1)));
            body.Add(Expression.Assign(count, Expression.Constant(0)));
            body.Add(Expression.Assign(matched, Expression.Constant(false)));
            body.Add(Expression.Assign(
                         repl_list,
                         Expression.New(
                             typeof(List<RxReplacement>).GetConstructor(
                                 new Type[0]))));
            body.Add(loop);

            // replace substrings
            body.Add(
                Expression.Call(
                    typeof(Regex).GetMethod("ReplaceSubstrings"),
                    Runtime,
                    scalar,
                    str,
                    repl_list));

            // return value
            var result =
                Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeInt),
                    Runtime,
                    count);

            body.Add(
                Expression.Condition(
                    Expression.Equal(
                        OpContext(rm),
                        Expression.Constant(Opcode.ContextValues.LIST)),
                    Expression.New(
                        typeof(P5List).GetConstructor(ProtoRuntimeAny),
                        Runtime,
                        result),
                    result, typeof(IP5Any)));

            return Expression.Block(typeof(IP5Any), vars, body);
        }

        private Expression GenerateSubstitution(Subroutine sub, RegexMatch rm)
        {
            var scalar = Expression.Variable(typeof(P5Scalar));
            var str = Expression.Variable(typeof(string));
            var replace = Expression.Variable(typeof(IP5Any));
            var init_scalar =
                Expression.Assign(scalar, Generate(sub, rm.Childs[0]));
            var init_str =
                Expression.Assign(
                    str,
                    Expression.Call(
                        scalar,
                        typeof(IP5Any).GetMethod("AsString"),
                        Runtime));

            var replace_list = new List<Expression>();

            // at this point all nested scopes have been generated
            replace_list.Add(
                Expression.Assign(replace, ValueBlocks[rm.To]));

            // replace in string
            var rxstate = Expression.Field(
                Runtime,
                typeof(Runtime).GetField("LastMatch"));

            replace_list.Add(
                Expression.Call(
                    scalar,
                    typeof(P5Scalar).GetMethod("SpliceSubstring"),
                    Runtime,
                    Expression.Field(
                        rxstate,
                        typeof(RxResult).GetField("Start")),
                    Expression.Field(
                        rxstate,
                        typeof(RxResult).GetField("End")),
                    replace));

            // return true at end of replacement
            replace_list.Add(Expression.Constant(true));

            var match = Expression.Call(
                Generate(sub, rm.Childs[1]),
                typeof(Regex).GetMethod("MatchString"),
                Runtime,
                str,
                Expression.Constant(-1),
                GetSavedRxState(rm.Index));
            var repl = Expression.Condition(
                match,
                Expression.Block(typeof(bool), replace_list),
                Expression.Constant(false));

            var vars = new List<ParameterExpression>();
            vars.Add(scalar);
            vars.Add(str);
            vars.Add(replace);

            var exps = new List<Expression>();
            exps.Add(init_scalar);
            exps.Add(init_str);
            exps.Add(
                Expression.New(
                    typeof(P5Scalar).GetConstructor(ProtoRuntimeBool),
                    Runtime,
                    repl));

            return Expression.Block(typeof(P5Scalar), vars, exps);
        }

        private LabelTarget SubLabel;
        private ParameterExpression Runtime, Arguments, Context, Pad;
        private List<ParameterExpression> Variables, Lexicals, Temporaries, LexStates, RxStates;
        private List<LabelTarget> BlockLabels;
        private List<Expression> Blocks;
        private Dictionary<int, Expression> ValueBlocks;
        private bool IsMain;
        private ModuleGenerator ModuleGenerator;
        private List<ModuleGenerator.SubInfo> Subroutines;
    }

    public class Generator
    {
        public Generator(Runtime r)
        {
            Runtime = r;
        }

        public P5Code Generate(string assembly_name, CompilationUnit cu)
        {
            var file = new System.IO.FileInfo(cu.FileName);
            AssemblyName asm_name = new AssemblyName(assembly_name != null ? assembly_name : file.Name);
            AssemblyBuilder asm_builder =
                System.AppDomain.CurrentDomain.DefineDynamicAssembly(
                    asm_name, AssemblyBuilderAccess.RunAndSave);

            Type daType = typeof(DebuggableAttribute);
            ConstructorInfo daCtor = daType.GetConstructor(
                new Type[] { typeof(DebuggableAttribute.DebuggingModes) });
            CustomAttributeBuilder daBuilder = new CustomAttributeBuilder(
                daCtor, new object[] {
                    DebuggableAttribute.DebuggingModes.DisableOptimizations|
                    DebuggableAttribute.DebuggingModes.Default });
            asm_builder.SetCustomAttribute(daBuilder);

            ModuleBuilder mod_builder =
                asm_builder.DefineDynamicModule(asm_name.Name,
                                                asm_name.Name + ".dll",
                                                true);

            // FIXME should at least be the module name with which the
            //       file was loaded, in case multiple modules are
            //       compiled to the same file; works for now
            TypeBuilder perl_module = mod_builder.DefineType(file.Name, TypeAttributes.Public);
            ModuleGenerator perl_mod_generator = new ModuleGenerator(perl_module);

            for (int i = 0; i < cu.Subroutines.Length; ++i)
            {
                var sub = cu.Subroutines[i];

                if (sub.IsRegex)
                    perl_mod_generator.AddRegexInfo(sub);
                else
                    perl_mod_generator.AddSubInfo(sub);
            }

            for (int i = 0; i < cu.Subroutines.Length; ++i)
            {
                var sub = cu.Subroutines[i];

                if (sub.IsRegex)
                    perl_mod_generator.AddRegex(i, sub);
                else
                    perl_mod_generator.AddMethod(i, sub);
            }

            return perl_mod_generator.CompleteGeneration(Runtime);
        }

        Runtime Runtime;
    }
}
