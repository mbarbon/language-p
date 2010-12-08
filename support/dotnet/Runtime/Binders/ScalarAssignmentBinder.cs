using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class P5ScalarAssignmentBinder : DynamicMetaObjectBinder
    {
        public P5ScalarAssignmentBinder(Runtime _runtime)
        {
            runtime = _runtime;
        }

        public override DynamicMetaObject Bind(DynamicMetaObject target, DynamicMetaObject[] args)
        {
            DynamicMetaObject arg = args[0];

            return BindFallback(target, arg);
        }

        private DynamicMetaObject BindFallback(DynamicMetaObject target, DynamicMetaObject arg)
        {
            return new DynamicMetaObject(
                Expression.Convert(
                Expression.Call(
                    Utils.CastRuntime(target),
                    target.RuntimeType.GetMethod("Assign"),
                    Expression.Constant(runtime),
                    Utils.CastRuntime(arg)),
                target.RuntimeType),
                Utils.RestrictToRuntimeType(arg, target));
        }

        private Runtime runtime;
    }
}
