using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class SymbolTable
    {       
        public SymbolTable(Runtime runtime)
        {
            symbols = new Dictionary<string, Typeglob>();
        }

        public Scalar GetOrCreateScalar(Runtime runtime, string name)
        {
            var glob = GetOrCreateGlob(runtime, name);
            Scalar scalar;
            if ((scalar = glob.Scalar) == null)
                scalar = glob.Scalar = new Scalar(runtime);

            return scalar;
        }

        public Array GetOrCreateArray(Runtime runtime, string name)
        {
            var glob = GetOrCreateGlob(runtime, name);
            Array array;
            if ((array = glob.Array) == null)
                array = glob.Array = new Array(runtime);

            return array;
        }

        public Handle GetOrCreateHandle(Runtime runtime, string name)
        {
            var glob = GetOrCreateGlob(runtime, name);
            Handle handle;
            if ((handle = glob.Handle) == null)
                handle = glob.Handle = new Handle(runtime);

            return handle;
        }

        public Typeglob GetOrCreateGlob(Runtime runtime, string name)
        {
            Typeglob glob;
            if (!symbols.TryGetValue(name, out glob))
            {
                glob = new Typeglob(runtime);
                symbols.Add(name, glob);
            }

            return glob;
        }
        
        protected Dictionary<string, Typeglob> symbols;
    }

    public class MainSymbolTable : SymbolTable
    {
        public MainSymbolTable(Runtime runtime) : base(runtime)
        {
            var stdout = GetOrCreateGlob(runtime, "STDOUT");
            stdout.Handle = new Handle(runtime);
        }
    }
}
