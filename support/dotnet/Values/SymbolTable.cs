using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5SymbolTable
    {       
        public P5SymbolTable(Runtime runtime)
        {
            symbols = new Dictionary<string, P5Typeglob>();
        }

        public P5Scalar GetOrCreateScalar(Runtime runtime, string name)
        {
            var glob = GetOrCreateGlob(runtime, name);
            P5Scalar scalar;
            if ((scalar = glob.Scalar) == null)
                scalar = glob.Scalar = new P5Scalar(runtime);

            return scalar;
        }

        public P5Array GetOrCreateArray(Runtime runtime, string name)
        {
            var glob = GetOrCreateGlob(runtime, name);
            P5Array array;
            if ((array = glob.Array) == null)
                array = glob.Array = new P5Array(runtime);

            return array;
        }

        public P5Hash GetOrCreateHash(Runtime runtime, string name)
        {
            var glob = GetOrCreateGlob(runtime, name);
            P5Hash hash;
            if ((hash = glob.Hash) == null)
                hash = glob.Hash = new P5Hash(runtime);

            return hash;
        }

        public P5Handle GetOrCreateHandle(Runtime runtime, string name)
        {
            var glob = GetOrCreateGlob(runtime, name);
            P5Handle handle;
            if ((handle = glob.Handle) == null)
                handle = glob.Handle = new P5Handle(runtime);

            return handle;
        }

        public P5Typeglob GetOrCreateGlob(Runtime runtime, string name)
        {
            P5Typeglob glob;
            if (!symbols.TryGetValue(name, out glob))
            {
                glob = new P5Typeglob(runtime);
                symbols.Add(name, glob);
            }

            return glob;
        }

        public P5Code GetCode(Runtime runtime, string name)
        {
            P5Typeglob glob;
            if (symbols.TryGetValue(name, out glob))
                return glob.Code;

            return null;
        }

        public void SetCode(Runtime runtime, string name, P5Code code)
        {
            P5Typeglob glob = GetOrCreateGlob(runtime, name);
            glob.Code = code;
        }

        protected Dictionary<string, P5Typeglob> symbols;
    }

    public class P5MainSymbolTable : P5SymbolTable
    {
        public P5MainSymbolTable(Runtime runtime) : base(runtime)
        {
            var stdout = GetOrCreateGlob(runtime, "STDOUT");
            stdout.Handle = new P5Handle(runtime);
        }
    }
}
