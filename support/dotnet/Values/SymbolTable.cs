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
}
