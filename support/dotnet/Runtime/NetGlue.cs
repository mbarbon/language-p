using org.mbarbon.p.values;
using System.Reflection;
using Type = System.Type;

namespace org.mbarbon.p.runtime
{
    public class NetGlue
    {
        private static bool Matches(Runtime runtime, Type type, IP5Any value)
        {
            var scalar = value as P5Scalar;

            if (type == typeof(int))
            {
                if (scalar != null && !scalar.IsInteger(runtime))
                    return false;

                return true;
            }

            var net_wrapper = scalar.Body as P5NetWrapper;
            if (net_wrapper == null)
                return false;
            if (type != net_wrapper.Object.GetType())
                return false;

            return true;
        }

        private static bool Matches(Runtime runtime, MethodBase meth, P5Scalar[] args)
        {
            var parms = meth.GetParameters();

            if (parms.Length != args.Length)
                return false;

            int index = 0;
            foreach (var parm in parms)
                if (!Matches(runtime, parm.ParameterType, args[index]))
                    return false;

            return true;
        }

        private static object Convert(Runtime runtime, IP5Any arg, Type type)
        {
            if (type == typeof(int))
                return arg.AsInteger(runtime);

            var scalar = arg as P5Scalar;

            // fallback
            var net_wrapper = scalar.Body as P5NetWrapper;
            return net_wrapper.Object;
        }

        private static object[] ConvertArgs(Runtime runtime, MethodBase meth, P5Scalar[] args)
        {
            var parms = meth.GetParameters();
            var res = new object[args.Length];

            for (int i = 0; i < args.Length; ++i)
                res[i] = Convert(runtime, args[i], parms[i].ParameterType);

            return res;
        }

        public static IP5Any GetClass(Runtime runtime, string name)
        {
            var cls = System.Type.GetType(name);
            var wrapper = new P5NetWrapper(runtime, cls);

            return new P5Scalar(wrapper);
        }

        public static IP5Any CallConstructor(Runtime runtime, P5Scalar wrapper,
                                             P5Scalar[] args)
        {
            var net_wrapper = wrapper.Body as P5NetWrapper;
            var type = net_wrapper.Object as System.Type;

            foreach (var ctor in type.GetConstructors())
            {
                if (!Matches(runtime, ctor, args))
                    continue;
                var net_args = ConvertArgs(runtime, ctor, args);

                var res = ctor.Invoke(net_args);
                var res_wrapper = new P5NetWrapper(runtime, res);

                return new P5Scalar(res_wrapper);
            }

            throw new System.Exception("Constructor not found");
        }

        public static IP5Any CallMethod(Runtime runtime, P5Scalar wrapper,
                                        string method, P5Scalar[] args)
        {
            var net_wrapper = wrapper.Body as P5NetWrapper;
            var obj = net_wrapper.Object;
            var type = obj.GetType();

            foreach (var meth in type.GetMethods())
            {
                if (meth.Name != method)
                    continue;
                if (!Matches(runtime, meth, args))
                    continue;
                var net_args = ConvertArgs(runtime, meth, args);

                var res = meth.Invoke(obj, net_args);
                var res_wrapper = new P5NetWrapper(runtime, res);

                return new P5Scalar(res_wrapper);
            }

            throw new System.Exception("Method not found");
        }

        public static IP5Any GetProperty(Runtime runtime, P5Scalar wrapper,
                                         string name)
        {
            var net_wrapper = wrapper.Body as P5NetWrapper;
            var obj = net_wrapper.Object;
            var prop = obj.GetType().GetProperty(name);
            var val = prop.GetValue(obj, null);

            var res_wrapper = new P5NetWrapper(runtime, val);

            return new P5Scalar(res_wrapper);
        }

        public static void SetProperty(Runtime runtime, P5Scalar wrapper,
                                       string name, IP5Any value)
        {
            var net_wrapper = wrapper.Body as P5NetWrapper;
            var obj = net_wrapper.Object;
            var prop = obj.GetType().GetProperty(name);

            if (!Matches(runtime, prop.PropertyType, value))
                throw new System.Exception("Invalid type");

            prop.SetValue(obj, Convert(runtime, value, prop.PropertyType), null);
        }
    }
}
