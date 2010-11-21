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

        private static bool IsAny(DynamicMetaObject o)
        {
            return typeof(IP5Any).IsAssignableFrom(o.RuntimeType);
        }

        private static bool IsScalar(DynamicMetaObject o)
        {
            return typeof(P5Scalar).IsAssignableFrom(o.RuntimeType);
        }

        private Expression CastAny(DynamicMetaObject o)
        {
            return Expression.Convert(o.Expression, typeof(IP5Any));
        }

        private Expression CastScalar(DynamicMetaObject o)
        {
            return Expression.Convert(o.Expression, typeof(P5Scalar));
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
                    CastScalar(target));
                break;
            case ExpressionType.Negate:
                default_conversion = "AsInteger";
                default_result = typeof(int);
                break;
            case ExpressionType.Not:
                default_conversion = "AsBoolean";
                default_result = typeof(bool);
                break;
            default:
                return null;
            }

            if (IsScalar(target) && scalar_expression != null)
                return new DynamicMetaObject(
                    scalar_expression,
                    BindingRestrictions.GetTypeRestriction(target.Expression, typeof(P5Scalar)));
            else if (IsAny(target))
                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new[] { typeof(Runtime), default_result }),
                        Expression.Constant(Runtime),
                        Expression.MakeUnary(
                            Operation,
                            Expression.Call(
                                CastAny(target),
                                typeof(IP5Any).GetMethod(default_conversion),
                                Expression.Constant(Runtime)),
                            null)),
                    BindingRestrictions.GetTypeRestriction(target.Expression, typeof(P5Scalar)));

            return null;
        }

        private Runtime Runtime;
    }
}
