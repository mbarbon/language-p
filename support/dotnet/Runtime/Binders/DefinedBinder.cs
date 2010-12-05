using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class P5DefinedBinder : DynamicMetaObjectBinder
    {
        public P5DefinedBinder(Runtime _runtime)
        {
            runtime = _runtime;
        }

        public override DynamicMetaObject Bind(DynamicMetaObject target, DynamicMetaObject[] args)
        {
            return new DynamicMetaObject(
                Expression.New(
                    typeof(P5Scalar).GetConstructor(new[] { typeof(Runtime), typeof(bool) }),
                    Expression.Constant(runtime),
                    Expression.Call(
                        Utils.CastRuntime(target),
                        target.RuntimeType.GetMethod("IsDefined"),
                        Expression.Constant(runtime))),
                Utils.RestrictToRuntimeType(target));
        }

        Runtime runtime;
    }
}
