using org.mbarbon.p.runtime;
using org.mbarbon.p.values;

namespace org.mbarbon.p
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            var runtime = new Runtime();

            var x = runtime.SymbolTable.GetOrCreateScalar(runtime, "x");
            var n = new Scalar(runtime, 1);
            x.Assign(runtime, n);

            var p = new List(runtime);
            p.Push(runtime, new Scalar(runtime, "X is "));
            p.Push(runtime, x);
            Builtins.Print(runtime, p);
        }
    }
}