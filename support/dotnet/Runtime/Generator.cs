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
        }

        public LambdaExpression Generate(Subroutine sub)
        {
            List<Expression> exps = new List<Expression>();
            Generate(sub.BasicBlocks[0], exps);
            var block = Expression.Block(typeof(void), Variables, exps);
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
            case Opcode.OpNumber.OP_CONSTANT_STRING:
                var ctor = typeof(Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(string) });
                return Expression.New(ctor, new Expression[] { Runtime, Expression.Constant(((ConstantString)op).Value) });
            case Opcode.OpNumber.OP_GLOBAL:
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
                    throw new System.Exception(string.Format("Unhandled {0:D}", gop.Slot));
                }
                var gets = typeof(SymbolTable).GetMethod(name);
                return Expression.Call(Expression.Field(Runtime, st), gets, Runtime, Expression.Constant(gop.Name));
            case Opcode.OpNumber.OP_MAKE_LIST:
                List<Expression> data = new List<Expression>();
                foreach (var i in op.Childs)
                    data.Add(Generate(i));
                return Expression.New(typeof(org.mbarbon.p.values.List).GetConstructor(new System.Type[] {typeof(Runtime), typeof(IAny[])}),
                                    new Expression[] { Runtime, Expression.NewArrayInit(typeof(IAny), data) });
            case Opcode.OpNumber.OP_PRINT:
                return Expression.Call(typeof(Builtins).GetMethod("Print"), Runtime,
                                     Expression.Convert(Generate(op.Childs[0]), typeof(org.mbarbon.p.values.List)));
            case Opcode.OpNumber.OP_END:
                return Expression.Return(SubLabel);
            default:
                throw new System.Exception(string.Format("Unhandled {0:D}", op.Number));
            }
        }

        private LabelTarget SubLabel;
        private ParameterExpression Runtime;
        private List<ParameterExpression> Variables;
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
