using org.mbarbon.p.runtime;
using org.mbarbon.p.values;

using System.Linq;
using System.Linq.Expressions;
using System.Collections.Generic;

namespace org.mbarbon.p
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            var runtime = new Runtime();
            var cu = Serializer.ReadCompilationUnit(runtime, args[0]);

            // TODO used for bootstrap, add a flag to choose it a runtime
            runtime.NativeRegex = true;

            try
            {
                P5Code main = new Generator(runtime).Generate(null, cu);
                main.CallMain(runtime);
            }
            catch (System.Reflection.TargetInvocationException te)
            {
                var e = te.InnerException as P5Exception;

                if (e == null)
                {
                    System.Console.WriteLine();
                    System.Console.WriteLine(te.InnerException.ToString());
                }
                else
                    System.Console.WriteLine(e.AsString(runtime));
            }
            catch (P5Exception e)
            {
                System.Console.WriteLine(e.AsString(runtime));
            }
        }
    }
}