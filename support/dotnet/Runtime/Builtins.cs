using org.mbarbon.p.values;

namespace org.mbarbon.p.runtime
{
    public class Builtins
    {
        public static P5Scalar Print(Runtime runtime, P5List args)
        {
            P5Handle handle = (P5Handle)args.GetItem(runtime, 0);
            
            // wrong but works well enough for now
            for (int i = 1, m = args.GetCount(runtime); i < m; ++i)
            {
                handle.Write(runtime, args.GetItem(runtime, i), 0, -1);
            }

            return new P5Scalar(runtime, 1);
        }
    }
}
