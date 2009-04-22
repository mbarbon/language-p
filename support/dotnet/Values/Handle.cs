using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class Handle : IAny
    {
        public Handle(Runtime runtime)
        {
        }

        public int Write(Runtime runtime, IAny scalar, int offset, int length)
        {
            // FIXME cheating
            System.Console.Write(scalar.AsString(runtime));

            return 1;
        }

        public IAny AsScalar(Runtime runtime) { return this; }
        public string AsString(Runtime runtime) { return null; }
        public int AsInteger(Runtime runtime) { return 0; }
        public double AsFloat(Runtime runtime) { return 0; }
    }
}
