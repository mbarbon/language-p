using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;
using StringSplitOptions = System.StringSplitOptions;

namespace org.mbarbon.p.values
{
    public class P5SymbolTable
    {
        public P5SymbolTable(Runtime runtime)
        {
            symbols = new Dictionary<string, P5Typeglob>();
            packages = new Dictionary<string, P5SymbolTable>();
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
                handle = glob.Handle = new P5Handle(runtime, null, null);

            return handle;
        }

        public P5Typeglob GetGlob(Runtime runtime, string name)
        {
            string[] packs = name.Split(separator, StringSplitOptions.None);
            P5SymbolTable st = GetPackage(runtime, packs, true, false);
            P5Typeglob glob;

            if (st == null)
                return null;
            if (!st.symbols.TryGetValue(packs[packs.Length - 1], out glob))
                return null;

            return glob;
        }

        public P5Typeglob GetOrCreateGlob(Runtime runtime, string name)
        {
            string[] packs = name.Split(separator, StringSplitOptions.None);
            P5SymbolTable st = GetPackage(runtime, packs, true, true);

            P5Typeglob glob;
            if (!st.symbols.TryGetValue(packs[packs.Length - 1], out glob))
            {
                glob = new P5Typeglob(runtime);
                ApplyMagic(runtime, packs[packs.Length - 1], glob);
                st.symbols.Add(packs[packs.Length - 1], glob);
            }

            return glob;
        }

        public P5Code GetCode(Runtime runtime, string name)
        {
            P5Typeglob glob = GetGlob(runtime, name);
            if (glob != null)
                return glob.Code;

            return null;
        }

        public void SetCode(Runtime runtime, string name, P5Code code)
        {
            P5Typeglob glob = GetOrCreateGlob(runtime, name);
            glob.Code = code;
        }

        public P5SymbolTable GetOrCreatePackage(Runtime runtime, string pack)
        {
            string[] packs = pack.Split(separator, StringSplitOptions.None);

            return GetPackage(runtime, packs, false, true);
        }

        public P5SymbolTable GetOrCreatePackage(Runtime runtime, string pack,
                                                bool skip_last)
        {
            string[] packs = pack.Split(separator, StringSplitOptions.None);

            return GetPackage(runtime, packs, skip_last, true);
        }

        virtual protected void ApplyMagic(Runtime runtime, string name,
                                          P5Typeglob symbol)
        {
            if (name.Length == 0 || name[0] == '0')
                return;
            for (int i = 0; i < name.Length; ++i)
                if (!char.IsDigit(name[i]))
                    return;

            symbol.Scalar = new P5Capture(runtime, int.Parse(name));
        }

        internal P5SymbolTable GetPackage(Runtime runtime, string pack,
                                          bool skip_last, bool create)
        {
            string[] packs = pack.Split(separator, StringSplitOptions.None);

            return GetPackage(runtime, packs, skip_last, create);
        }

        internal P5SymbolTable GetPackage(Runtime runtime, string[] packs,
                                          bool skip_last, bool create)
        {
            P5SymbolTable current = this, next;

            int last = packs.Length + (skip_last ? -1 : 0);
            for (int i = 0; i < last; ++i)
            {
                if (!current.packages.TryGetValue(packs[i], out next))
                {
                    if (!create)
                        return null;

                    next = new P5SymbolTable(runtime);
                    current.packages.Add(packs[i], next);
                }
                current = next;
            }

            return current;
        }

        public P5Code FindMethod(Runtime runtime, string method)
        {
            var code = GetCode(runtime, method);
            if (code != null)
                return code;

            P5Typeglob isa;
            if (!symbols.TryGetValue("ISA", out isa))
                return null;
            P5Array isa_array = isa.Array;
            if (isa_array == null)
                return null;

            var main_st = runtime.SymbolTable;
            foreach (var c in isa_array)
            {
                var c_str = c.AsString(runtime);
                var super = main_st.GetPackage(runtime, c_str, false, false);
                if (super == null)
                    continue;

                code = super.FindMethod(runtime, method);
                if (code != null)
                    return code;
            }

            return null;
        }

        protected readonly string[] separator = new string [] {"::"};
        protected Dictionary<string, P5Typeglob> symbols;
        protected Dictionary<string, P5SymbolTable> packages;
    }

    public class P5MainSymbolTable : P5SymbolTable
    {
        public P5MainSymbolTable(Runtime runtime) : base(runtime)
        {
            var stdout = GetOrCreateGlob(runtime, "STDOUT");
            stdout.Handle = new P5Handle(runtime, null, System.Console.Out);

            var stdin = GetOrCreateGlob(runtime, "STDIN");
            stdin.Handle = new P5Handle(runtime, System.Console.In, null);

            var stderr = GetOrCreateGlob(runtime, "STDERR");
            stderr.Handle = new P5Handle(runtime, null, System.Console.Error);
        }
    }
}
