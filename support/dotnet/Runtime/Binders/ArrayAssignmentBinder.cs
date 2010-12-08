using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class P5ArrayAssignmentBinder : DynamicMetaObjectBinder
    {
        public P5ArrayAssignmentBinder(Runtime runtime, Opcode.ContextValues cxt)
        {
            Runtime = runtime;
            Context = cxt;
        }

        public override DynamicMetaObject Bind(DynamicMetaObject target, DynamicMetaObject[] args)
        {
            DynamicMetaObject arg = args[0];

            if (arg.RuntimeType == typeof(P5Range))
                return BindRange(target, arg);

            return BindFallback(target, arg);
        }

        private Expression ContextExpression()
        {
            if (Context == Opcode.ContextValues.CALLER)
                return Expression.Call(
                    Expression.Constant(Runtime),
                    typeof(Runtime).GetMethod("CurrentContext"));
            else
                return Expression.Constant(Context);
        }

        private DynamicMetaObject BindRange(DynamicMetaObject target, DynamicMetaObject arg)
        {
            var lvalue = Expression.Parameter(target.RuntimeType);
            var rvalue = Expression.Parameter(arg.RuntimeType);
            var assignment = Expression.Call(
                lvalue,
                target.RuntimeType.GetMethod("AssignIterator"),
                Expression.Constant(Runtime),
                Expression.Call(
                    rvalue,
                    typeof(IP5Enumerable).GetMethod("GetEnumerator"),
                    Expression.Constant(Runtime)));
            var result = Expression.Condition(
                Expression.Equal(
                    ContextExpression(),
                    Expression.Constant(Opcode.ContextValues.SCALAR)),
                Expression.New(
                    typeof(P5Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(int) }),
                    Expression.Constant(Runtime),
                    Expression.Call(
                        rvalue,
                        typeof(P5Range).GetMethod("GetCount"))),
                lvalue,
                typeof(IP5Any));

            return new DynamicMetaObject(
                Expression.Block(
                    typeof(IP5Any),
                    new ParameterExpression[] { lvalue, rvalue },
                    new Expression[] {
                        Expression.Assign(lvalue, Utils.CastRuntime(target)),
                        Expression.Assign(rvalue, Utils.CastRuntime(arg)),
                        assignment,
                        result } ),
                Utils.RestrictToRuntimeType(arg, target));
        }

        private DynamicMetaObject BindFallback(DynamicMetaObject target, DynamicMetaObject arg)
        {
            var assign_result = Expression.Parameter(typeof(int));
            var lvalue = Expression.Parameter(target.RuntimeType);
            var assignment = Expression.Call(
                lvalue,
                target.RuntimeType.GetMethod("AssignArray"),
                Expression.Constant(Runtime),
                Utils.CastAny(arg));
            var result = Expression.Condition(
                Expression.Equal(
                    ContextExpression(),
                    Expression.Constant(Opcode.ContextValues.SCALAR)),
                Expression.New(
                    typeof(P5Scalar).GetConstructor(new System.Type[] { typeof(Runtime), typeof(int) }),
                    Expression.Constant(Runtime),
                    assign_result),
                lvalue,
                typeof(IP5Any));
            var expression = Expression.Block(
                typeof(IP5Any),
                new ParameterExpression[] { assign_result, lvalue },
                new Expression[] {
                    Expression.Assign(lvalue, Utils.CastRuntime(target)),
                    Expression.Assign(assign_result, assignment),
                    result } );

            return new DynamicMetaObject(
                expression,
                Utils.RestrictToRuntimeType(arg, target));
        }

        private Runtime Runtime;
        private Opcode.ContextValues Context;
    }
}
