using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class P5UnaryIncrementBinder : DynamicMetaObjectBinder
    {
        public P5UnaryIncrementBinder(ExpressionType _operation, Runtime _runtime)
        {
            runtime = _runtime;
            operation = _operation;
        }

        public override DynamicMetaObject Bind(DynamicMetaObject target, DynamicMetaObject[] args)
        {
            if (Utils.IsScalar(target))
            {
                string method;
                switch (operation)
                {
                case ExpressionType.PreIncrementAssign:
                    method = "PreIncrement";
                    break;
                case ExpressionType.PreDecrementAssign:
                    method = "PreDecrement";
                    break;
                case ExpressionType.PostIncrementAssign:
                    method = "PostIncrement";
                    break;
                case ExpressionType.PostDecrementAssign:
                    method = "PostDecrement";
                    break;
                default:
                    throw new System.Exception("Invalid operation");
                }

                return new DynamicMetaObject(
                    Expression.Call(
                        Utils.CastScalar(target),
                        typeof(P5Scalar).GetMethod(method),
                        Expression.Constant(runtime)),
                    Utils.RestrictToScalar(target));
            }

            return null;
        }

        private Runtime runtime;
        private ExpressionType operation;
    }
}
