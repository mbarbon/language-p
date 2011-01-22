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

            if (   type == typeof(bool)
                || type == typeof(string)
                || type == typeof(char))
                return true;

            if (type == typeof(int))
            {
                if (scalar != null && !scalar.IsInteger(runtime))
                    return false;

                return true;
            }

            if (typeof(IP5Any).IsAssignableFrom(type))
            {
                if (type == value.GetType())
                    return true;
            }

            var net_wrapper = scalar.NetWrapper(runtime);
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
            {
                if (!Matches(runtime, parm.ParameterType, args[index]))
                    return false;
                ++index;
            }

            return true;
        }

        private static object Convert(Runtime runtime, IP5Any arg, Type type)
        {
            if (type == typeof(int))
                return arg.AsInteger(runtime);
            if (type == typeof(char))
                return arg.AsString(runtime)[0];
            if (type == typeof(bool))
                return arg.AsBoolean(runtime);
            if (type == typeof(string))
                return arg.AsString(runtime);

            var scalar = arg as P5Scalar;

            if (typeof(IP5Any).IsAssignableFrom(type))
                return arg;

            // fallback
            var net_wrapper = scalar.NetWrapper(runtime);
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

        private static IP5Any WrapNew(Runtime runtime, Opcode.ContextValues context,
                                      P5ScratchPad pad, P5Array args)
        {
            var count = args.GetCount(runtime);
            var arg = new P5Scalar[count - 1];

            for (int i = 1; i < count; ++i)
                arg[i - 1] = args.GetItem(runtime, i) as P5Scalar;

            var cls = pad[0] as P5Scalar;
            var pack = pad[1] as P5SymbolTable;
            var val = CallConstructor(runtime, cls, arg);
            var res = new P5Scalar(runtime, val);

            val.Bless(runtime, pack);

            return res;
        }

        public static IP5Any Extend(Runtime runtime, string pack, string name)
        {
            var cls = System.Type.GetType(name);
            var wrapper = new P5Scalar(new P5NetWrapper(runtime, cls));
            var stash = runtime.SymbolTable.GetPackage(runtime, pack);
            var pad = new P5ScratchPad();

            pad.Add(wrapper);
            pad.Add(stash);

            var glob = stash.GetStashGlob(runtime, "new", true);

            var code = new P5NativeCode(pack + "::new", new P5Code.Sub(WrapNew));

            code.ScratchPad = pad;
            glob.Code = code;

            return new P5Scalar(runtime);
        }

        public static IP5Any CallConstructor(Runtime runtime, P5Scalar wrapper,
                                             P5Scalar[] args)
        {
            var net_wrapper = wrapper.NetWrapper(runtime);
            var type = net_wrapper.Object as System.Type;

            return CallConstructor(runtime, type, args);
        }

        public static IP5Any CallConstructor(Runtime runtime, System.Type type,
                                             P5Scalar[] args)
        {
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
            var net_wrapper = wrapper.NetWrapper(runtime);
            var obj = net_wrapper.Object;

            return CallMethod(runtime, obj, method, args);
        }

        public static IP5Any CallMethod(Runtime runtime, object obj,
                                        string method, P5Scalar[] args)
        {
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

            throw new P5Exception(runtime, string.Format("Can't locate object method \"{0:S}\" via type \"{1:S}\"", method, type.FullName));
        }

        public static IP5Any GetProperty(Runtime runtime, P5Scalar wrapper,
                                         string name)
        {
            var net_wrapper = wrapper.NetWrapper(runtime);
            var obj = net_wrapper.Object;
            var prop = obj.GetType().GetProperty(name);
            var val = prop.GetValue(obj, null);

            var res_wrapper = new P5NetWrapper(runtime, val);

            return new P5Scalar(res_wrapper);
        }

        public static void SetProperty(Runtime runtime, P5Scalar wrapper,
                                       string name, IP5Any value)
        {
            var net_wrapper = wrapper.NetWrapper(runtime);
            var obj = net_wrapper.Object;
            var prop = obj.GetType().GetProperty(name);

            if (!Matches(runtime, prop.PropertyType, value))
                throw new System.Exception("Invalid type");

            prop.SetValue(obj, Convert(runtime, value, prop.PropertyType), null);
        }

        public static object UnwrapValue(IP5Any value, System.Type type)
        {
            var scalar = value as P5Scalar;
            if (scalar == null)
                return null;

            var wrapper = scalar.Body as P5NetWrapper;
            if (wrapper == null)
                return null;

            if (type.IsAssignableFrom(wrapper.Object.GetType()))
                return wrapper.Object;

            return null;
        }
    }
}
