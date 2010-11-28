using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class P5StringCompareBinder : BinaryOperationBinder
    {
        public P5StringCompareBinder(ExpressionType _op, Runtime _runtime) :
            base(_op)
        {
            runtime = _runtime;
        }

        public override DynamicMetaObject FallbackBinaryOperation(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            switch (Operation)
            {
            case ExpressionType.GreaterThan:
            case ExpressionType.GreaterThanOrEqual:
            case ExpressionType.LessThan:
            case ExpressionType.LessThanOrEqual:
                return BindRelOp(target, arg, errorSuggestion);
            case ExpressionType.Equal:
            case ExpressionType.NotEqual:
                return BindEqOp(target, arg, errorSuggestion);
            default:
                throw new System.Exception("Unhandled operation value");
            }
        }

        private DynamicMetaObject BindRelOp(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            if (Utils.IsAny(target) && Utils.IsAny(arg))
            {
                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new System.Type[] {typeof(Runtime), typeof(bool)}),
                        Expression.Constant(runtime),
                        Expression.MakeBinary(
                            Operation,
                            Expression.Call(
                                typeof(string).GetMethod("Compare", new[] { typeof(string), typeof(string) }),
                                Expression.Call(
                                    Utils.CastAny(target),
                                    typeof(IP5Any).GetMethod("AsString"),
                                    Expression.Constant(runtime)),
                                Expression.Call(
                                    Utils.CastAny(arg),
                                    typeof(IP5Any).GetMethod("AsString"),
                                    Expression.Constant(runtime))),
                            Expression.Constant(0))),
                    Utils.RestrictToRuntimeType(arg, target));
            }

            return null;
        }

        private DynamicMetaObject BindEqOp(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            if (Utils.IsAny(target) && Utils.IsAny(arg))
            {
                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new System.Type[] {typeof(Runtime), typeof(bool)}),
                        Expression.Constant(runtime),
                        Expression.MakeBinary(
                            Operation,
                            Expression.Call(
                                Utils.CastAny(target),
                                typeof(IP5Any).GetMethod("AsString"),
                                Expression.Constant(runtime)),
                            Expression.Call(
                                Utils.CastAny(arg),
                                typeof(IP5Any).GetMethod("AsString"),
                                Expression.Constant(runtime)))),
                    Utils.RestrictToRuntimeType(arg, target));
            }

            return null;
        }

        private Runtime runtime;
    }
}
