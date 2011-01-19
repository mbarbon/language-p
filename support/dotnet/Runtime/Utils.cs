using org.mbarbon.p.values;

using System.Dynamic;
using Microsoft.Scripting.Ast;

namespace org.mbarbon.p.runtime
{
    class Utils
    {
        public static bool IsAny(DynamicMetaObject o)
        {
            return typeof(IP5Any).IsAssignableFrom(o.RuntimeType);
        }

        public static bool IsScalar(DynamicMetaObject o)
        {
            return typeof(P5Scalar).IsAssignableFrom(o.RuntimeType);
        }

        public static Expression CastAny(DynamicMetaObject o)
        {
            return Expression.Convert(o.Expression, typeof(IP5Any));
        }

        public static Expression CastScalar(DynamicMetaObject o)
        {
            return Expression.Convert(o.Expression, typeof(P5Scalar));
        }

        public static Expression CastRuntime(DynamicMetaObject o)
        {
            return Expression.Convert(o.Expression, o.RuntimeType);
        }

        public static BindingRestrictions RestrictToRuntimeType(DynamicMetaObject a, DynamicMetaObject b)
        {
            return BindingRestrictions.GetTypeRestriction(a.Expression, a.RuntimeType)
                .Merge(BindingRestrictions.GetTypeRestriction(b.Expression, b.RuntimeType));
        }

        public static BindingRestrictions RestrictToRuntimeType(DynamicMetaObject a)
        {
            return BindingRestrictions.GetTypeRestriction(a.Expression, a.RuntimeType);
        }

        public static BindingRestrictions RestrictToScalar(DynamicMetaObject a, DynamicMetaObject b)
        {
            return BindingRestrictions.GetTypeRestriction(a.Expression, typeof(P5Scalar))
                .Merge(BindingRestrictions.GetTypeRestriction(b.Expression, typeof(P5Scalar)));
        }

        public static BindingRestrictions RestrictToScalar(DynamicMetaObject a)
        {
            return BindingRestrictions.GetTypeRestriction(a.Expression, typeof(P5Scalar));
        }

        public static BindingRestrictions RestrictToAny(DynamicMetaObject a, DynamicMetaObject b)
        {
            // no way to restrict to an interface: restrict to the type
            return RestrictToRuntimeType(a, b);
        }

        public static BindingRestrictions RestrictToAny(DynamicMetaObject a)
        {
            // no way to restrict to an interface: restrict to the type
            return RestrictToRuntimeType(a);
        }
    }
}
