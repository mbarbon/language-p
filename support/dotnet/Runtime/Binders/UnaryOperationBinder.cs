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
                return BindBitNot(target, errorSuggestion);
            default:
                return null;
            }
        }

        private DynamicMetaObject BindBitNot(DynamicMetaObject target, DynamicMetaObject errorSuggestion)
        {
            if (IsScalar(target))
                return new DynamicMetaObject(
                    Expression.Call(
                        typeof(Builtins).GetMethod("BitNot"),
                        Expression.Constant(Runtime),
                        CastScalar(target)),
                    BindingRestrictions.GetTypeRestriction(target.Expression, typeof(P5Scalar)));
            else if (IsAny(target))
                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new[] { typeof(Runtime), typeof(int) }),
                        Expression.Constant(Runtime),
                        Expression.OnesComplement(
                            Expression.Call(
                                CastAny(target),
                                typeof(IP5Any).GetMethod("AsInteger"),
                                Expression.Constant(Runtime)))),
                    BindingRestrictions.GetTypeRestriction(target.Expression, typeof(P5Scalar)));

            return null;
        }

        private Runtime Runtime;
    }
}
