using org.mbarbon.p.values;

namespace org.mbarbon.p.runtime
{
    public class Builtins
    {
        public static Scalar Print(Runtime runtime, List args)
        {
            Handle handle = (Handle)args.GetItem(runtime, 0);
            
            // wrong but works well enough for now
            for (int i = 1, m = args.GetCount(runtime); i < m; ++i)
            {
                handle.Write(runtime, args.GetItem(runtime, i), 0, -1);
            }

            return new Scalar(runtime, 1);
        }
    }
}
