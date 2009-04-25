using org.mbarbon.p.values;

using Microsoft.Linq.Expressions;
using System.Collections.Generic;

namespace org.mbarbon.p.runtime
{
    public class SubGenerator
    {
        public SubGenerator()
        {
            SubLabel = Expression.Label(typeof(void));
            Runtime = Expression.Parameter(typeof(Runtime), "runtime");
            Variables = new List<ParameterExpression>();
            BlockLabels = new List<LabelTarget>();
            Blocks = new List<Expression>();
        }

        private ParameterExpression GetVariable(int index)
        {
            while (Variables.Count <= index)
                Variables.Add(Expression.Variable(typeof(IAny)));

            return Variables[index];
        }

        public LambdaExpression Generate(Subroutine sub)
        {
            for (int i = 0; i < sub.BasicBlocks.Length; ++i)
                BlockLabels.Add(Expression.Label());
            for (int i = 0; i < sub.BasicBlocks.Length; ++i)
            {
                List<Expression> exps = new List<Expression>();
                exps.Add(Expression.Label(BlockLabels[i]));
                Generate(sub.BasicBlocks[i], exps);
                Blocks.Add(Expression.Block(typeof(void), exps));
            }
            var block = Expression.Block(typeof(void), Variables, Blocks);
            var l = Expression.Lambda(Expression.Label(SubLabel, block),
                                    new ParameterExpression[] { Runtime });

            return l;
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
            case Opcode.OpNumber.OP_CONSTANT_INTEGER:
            {
                var ctor = typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(int) });
                return Expression.New(ctor, new Expression[] { Runtime, Expression.Constant(((ConstantInt)op).Value) });
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
                return Expression.Return(SubLabel);
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
                return Expression.Goto(BlockLabels[((Jump)op).To], typeof(void));
            }
            case Opcode.OpNumber.OP_JUMP_IF_S_EQ:
            {
                Expression cmp = Expression.Equal(Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsString"), Runtime),
                                               Expression.Call(Generate(op.Childs[1]), typeof(IAny).GetMethod("AsString"), Runtime));
                Expression jump = Expression.Goto(BlockLabels[((Jump)op).To], typeof(void));

                return Expression.IfThen(cmp, jump);
            }
            case Opcode.OpNumber.OP_JUMP_IF_F_EQ:
            {
                Expression cmp = Expression.Equal(Expression.Call(Generate(op.Childs[0]), typeof(IAny).GetMethod("AsFloat"), Runtime),
                                               Expression.Call(Generate(op.Childs[1]), typeof(IAny).GetMethod("AsFloat"), Runtime));
                Expression jump = Expression.Goto(BlockLabels[((Jump)op).To]);

                return Expression.IfThen(cmp, jump);
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
            default:
                throw new System.Exception(string.Format("Unhandled opcode {0:S}", op.Number.ToString()));
            }
        }

        private LabelTarget SubLabel;
        private ParameterExpression Runtime;
        private List<ParameterExpression> Variables;
        private List<LabelTarget> BlockLabels;
        private List<Expression> Blocks;
    }

    public class Generator
    {       
        public Generator()
        {
        }

        public LambdaExpression Generate(CompilationUnit cu)
        {
            SubGenerator sg = new SubGenerator();

            return sg.Generate(cu.Subroutines[0]);
        }
    }
}
