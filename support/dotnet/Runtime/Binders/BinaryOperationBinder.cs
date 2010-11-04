using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class P5BinaryOperationBinder : BinaryOperationBinder
    {
        public P5BinaryOperationBinder(ExpressionType op, Runtime runtime) :
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

        public override DynamicMetaObject FallbackBinaryOperation(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            if (Operation == ExpressionType.Or || Operation == ExpressionType.And)
                return BindBitOp(target, arg, errorSuggestion);

            return null;
        }

        private DynamicMetaObject BindBitOp(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            string method_name = Operation == ExpressionType.Or ? "BitOr" : "BitAnd";

            if (IsScalar(target) && IsScalar(arg))
            {
                return new DynamicMetaObject(
                    Expression.Call(
                        typeof(Builtins).GetMethod(method_name),
                        Expression.Constant(Runtime),
                        CastScalar(target),
                        CastScalar(arg)),
                    BindingRestrictions.GetTypeRestriction(arg.Expression, typeof(P5Scalar))
                    .Merge(BindingRestrictions.GetTypeRestriction(target.Expression, typeof(P5Scalar))));
            }
            else if (IsAny(target) && IsAny(arg))
            {
                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new System.Type[] {typeof(Runtime), typeof(int)}),
                        new Expression[] {
                            Expression.Constant(Runtime),
                            Expression.MakeBinary(
                                Operation,
                                Expression.Call(
                                    CastAny(target),
                                    typeof(IP5Any).GetMethod("AsInteger"),
                                    Expression.Constant(Runtime)),
                                Expression.Call(
                                    CastAny(arg),
                                    typeof(IP5Any).GetMethod("AsInteger"),
                                    Expression.Constant(Runtime)))}),
                    BindingRestrictions.GetTypeRestriction(arg.Expression, arg.RuntimeType)
                    .Merge(BindingRestrictions.GetTypeRestriction(target.Expression, target.RuntimeType)));
            }

            return null;
        }

        private Runtime Runtime;
    }
}
