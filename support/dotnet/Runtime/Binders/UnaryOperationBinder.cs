using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class P5UnaryOperationBinder : UnaryOperationBinder
    {
        public P5UnaryOperationBinder(ExpressionType op, Runtime runtime) :
            base(op)
        {
            Runtime = runtime;
        }

        public override DynamicMetaObject FallbackUnaryOperation(DynamicMetaObject target, DynamicMetaObject errorSuggestion)
        {
            switch (Operation)
            {
            case ExpressionType.Not:
            case ExpressionType.Negate:
            case ExpressionType.OnesComplement:
                return BindOperation(target, errorSuggestion);
            default:
                return null;
            }
        }

        private DynamicMetaObject BindOperation(DynamicMetaObject target, DynamicMetaObject errorSuggestion)
        {
            string default_conversion;
            System.Type default_result;
            Expression scalar_expression = null;

            switch (Operation)
            {
            case ExpressionType.OnesComplement:
                default_conversion = "AsInteger";
                default_result = typeof(int);
                scalar_expression = Expression.Call(
                    typeof(Builtins).GetMethod("BitNot"),
                    Expression.Constant(Runtime),
                    Utils.CastScalar(target));
                break;
            case ExpressionType.Negate:
                default_conversion = "AsInteger";
                default_result = typeof(int);
                scalar_expression = Expression.Call(
                    typeof(Builtins).GetMethod("Negate"),
                    Expression.Constant(Runtime),
                    Utils.CastScalar(target));
                break;
            case ExpressionType.Not:
                default_conversion = "AsBoolean";
                default_result = typeof(bool);
                break;
            default:
                return null;
            }

            if (Utils.IsScalar(target) && scalar_expression != null)
                return new DynamicMetaObject(
                    scalar_expression,
                    Utils.RestrictToScalar(target));
            else if (Utils.IsAny(target))
                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new[] { typeof(Runtime), default_result }),
                        Expression.Constant(Runtime),
                        Expression.MakeUnary(
                            Operation,
                            Expression.Call(
                                Utils.CastAny(target),
                                typeof(IP5Any).GetMethod(default_conversion),
                                Expression.Constant(Runtime)),
                            null)),
                    Utils.RestrictToRuntimeType(target));

            return null;
        }

        private Runtime Runtime;
    }
}
