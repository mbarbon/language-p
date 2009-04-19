using org.mbarbon.p.values;

namespace org.mbarbon.p.runtime
{
    public class Builtins
    {
        public static Scalar Print(Runtime runtime, List args)
        {
            // wrong but works well enough for now
            foreach (var i in args)
            {
                System.Console.Write(i.AsString(runtime));
            }

            return new Scalar(runtime, 1);
        }
    }
}
