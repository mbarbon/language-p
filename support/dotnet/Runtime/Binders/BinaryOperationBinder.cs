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
            switch (Operation)
            {
            case ExpressionType.Or:
            case ExpressionType.OrAssign:
            case ExpressionType.And:
            case ExpressionType.AndAssign:
                return BindBitOp(target, arg, errorSuggestion);
            case ExpressionType.Add:
            case ExpressionType.Subtract:
            case ExpressionType.Multiply:
            case ExpressionType.Divide:
                return BindArithOp(target, arg, errorSuggestion);
            case ExpressionType.GreaterThan:
                return BindRelOp(target, arg, errorSuggestion);
            default:
                return null;
            }
        }

        private DynamicMetaObject BindBitOp(DynamicMetaObject target, DynamicMetaObject arg, DynamicMetaObject errorSuggestion)
        {
            string method_name;
            bool is_assign;

            switch (Operation)
            {
            case ExpressionType.Or:
                method_name = "BitOr";
                is_assign = false;
                break;
            case ExpressionType.OrAssign:
                method_name = "BitOrAssign";
                is_assign = true;
                break;
            case ExpressionType.And:
                method_name = "BitAnd";
                is_assign = false;
                break;
            case ExpressionType.AndAssign:
                method_name = "BitAndAssign";
                is_assign = true;
                break;
            default:
                throw new System.Exception("Unhandled operation value");
            }

            if (IsScalar(target) && IsScalar(arg))
            {
                Expression expression;

                if (is_assign)
                    expression = Expression.Call(
                        typeof(Builtins).GetMethod(method_name),
                        Expression.Constant(Runtime),
                        CastScalar(target),
                        CastScalar(arg));
                else
                    expression = Expression.Call(
                        typeof(Builtins).GetMethod(method_name),
                        Expression.Constant(Runtime),
                        Expression.New(
                            typeof(P5Scalar).GetConstructor(new[] { typeof(IP5ScalarBody) }),
                            Expression.Constant(null, typeof(IP5ScalarBody))),
                        CastScalar(target),
                        CastScalar(arg));

                return new DynamicMetaObject(
                    expression,
                    BindingRestrictions.GetTypeRestriction(arg.Expression, typeof(P5Scalar))
                    .Merge(BindingRestrictions.GetTypeRestriction(target.Expression, typeof(P5Scalar))));
            }
            else if (IsAny(target) && IsAny(arg))
            {
                var value = Expression.MakeBinary(
                    Operation,
                    Expression.Call(
                        CastAny(target),
                        typeof(IP5Any).GetMethod("AsInteger"),
                        Expression.Constant(Runtime)),
                    Expression.Call(
                        CastAny(arg),
                        typeof(IP5Any).GetMethod("AsInteger"),
                        Expression.Constant(Runtime)));
                Expression expression;

                if (is_assign)
                    expression = Expression.Call(
                        CastScalar(target),
                        typeof(IP5Any).GetMethod("Assign"),
                        value);
                else
                    expression = Expression.New(
                        typeof(P5Scalar).GetConstructor(new[] {typeof(Runtime), typeof(int)}),
                        Expression.Constant(Runtime),
                        value);

                return new DynamicMetaObject(
                    expression,
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
                OverloadOperation op;
                string op_method;

                switch (Operation)
                {
                case ExpressionType.Add:
                    op = OverloadOperation.ADD;
                    op_method = "AddScalars";
                    break;
                case ExpressionType.Subtract:
                    op = OverloadOperation.SUBTRACT;
                    op_method = "SubtractScalars";
                    break;
                case ExpressionType.Multiply:
                    op = OverloadOperation.MULTIPLY;
                    op_method = "MultiplyScalars";
                    break;
                case ExpressionType.Divide:
                    op = OverloadOperation.DIVIDE;
                    op_method = "DivideScalars";
                    break;
                default:
                    throw new System.Exception("Unhandled overloaded operation");
                }

                return new DynamicMetaObject(
                    CallOverload(
                        target,
                        arg,
                        op,
                        Expression.Call(
                            typeof(Builtins).GetMethod(op_method),
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
                // TODO must handle double promotion (esp. for division)
                Expression op =
                    Expression.MakeBinary(
                        Operation,
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
                        op),
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
