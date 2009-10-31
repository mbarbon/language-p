using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{
    public class P5Exception : System.Exception
    {
        public P5Exception(Runtime runtime, IP5Any value)
            : base(value.AsScalar(runtime).AsString(runtime))
        {
        }
    }
}
