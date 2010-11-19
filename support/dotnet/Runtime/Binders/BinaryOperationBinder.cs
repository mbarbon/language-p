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
            if (Operation == ExpressionType.Add)
                return BindArithOp(target, arg, errorSuggestion);
            if (Operation == ExpressionType.GreaterThan)
                return BindRelOp(target, arg, errorSuggestion);

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

        private Expression CallOverload(DynamicMetaObject target, DynamicMetaObject arg, OverloadOperation op, Expression fallback)
        {
            return Expression.Coalesce(
                Expression.Call(
                    typeof(Builtins).GetMethod("CallOverload"),
                    Expression.Constant(Runtime),
                    Expression.Constant(op),
                    CastScalar(target),
                    CastScalar(arg)),
                fallback);
        }

        private DynamicMetaObject BindArithOp(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            if (IsScalar(target) || IsScalar(arg))
            {
                return new DynamicMetaObject(
                    CallOverload(
                        target,
                        arg,
                        OverloadOperation.ADD,
                        Expression.Call(
                            typeof(Builtins).GetMethod("AddScalars"),
                            Expression.Constant(Runtime),
                            CastScalar(target),
                            CastScalar(arg))),
                    BindingRestrictions.GetExpressionRestriction(
                        Expression.Or(
                            Expression.TypeEqual(target.Expression, typeof(P5Scalar)),
                            Expression.TypeEqual(arg.Expression, typeof(P5Scalar)))));
            }
            else if (IsAny(target) && IsAny(arg))
            {
                Expression sum =
                    Expression.Add(
                        Expression.Call(
                            CastAny(target),
                            typeof(IP5Any).GetMethod("AsInteger"),
                            Expression.Constant(Runtime)),
                        Expression.Call(
                            CastAny(target),
                            typeof(IP5Any).GetMethod("AsInteger"),
                            Expression.Constant(Runtime)));

                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new[] { typeof(Runtime), typeof(int) }),
                        Expression.Constant(Runtime),
                        sum),
                    BindingRestrictions.GetTypeRestriction(target.Expression, typeof(IP5Any))
                    .Merge(BindingRestrictions.GetTypeRestriction(arg.Expression, typeof(IP5Any))));
            }

            return null;
        }

        private DynamicMetaObject BindRelOp(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            if (IsAny(target) && IsAny(arg))
            {
                return new DynamicMetaObject(
                    Expression.New(
                        typeof(P5Scalar).GetConstructor(new System.Type[] {typeof(Runtime), typeof(bool)}),
                        new Expression[] {
                            Expression.Constant(Runtime),
                            Expression.MakeBinary(
                                Operation,
                                Expression.Call(
                                    CastAny(target),
                                    typeof(IP5Any).GetMethod("AsFloat"),
                                    Expression.Constant(Runtime)),
                                Expression.Call(
                                    CastAny(arg),
                                    typeof(IP5Any).GetMethod("AsFloat"),
                                    Expression.Constant(Runtime)))}),
                    BindingRestrictions.GetTypeRestriction(arg.Expression, arg.RuntimeType)
                    .Merge(BindingRestrictions.GetTypeRestriction(target.Expression, target.RuntimeType)));
            }

            return null;
        }

        private Runtime Runtime;
    }
}
