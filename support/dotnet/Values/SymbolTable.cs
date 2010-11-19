using Runtime = org.mbarbon.p.runtime.Runtime;
using System.Collections.Generic;
using StringSplitOptions = System.StringSplitOptions;
using Opcode = org.mbarbon.p.runtime.Opcode;
using Builtins = org.mbarbon.p.runtime.Builtins;

namespace org.mbarbon.p.values
{
    public class P5SymbolTable : P5Hash
    {
        public P5SymbolTable(Runtime runtime, string _name) : base(runtime)
        {
            name = _name;
        }

        public string GetName(Runtime runtime)
        {
            return name;
        }

        public P5Scalar GetScalar(Runtime runtime, string name, bool create)
        {
            var glob = GetGlob(runtime, name, true);
            if (glob.Scalar == null && create)
                glob.Scalar = new P5Scalar(runtime);

            return glob.Scalar;
        }

        public P5Scalar GetStashScalar(Runtime runtime, string name, bool create)
        {
            var glob = GetStashGlob(runtime, name, true);
            if (glob.Scalar == null && create)
                glob.Scalar = new P5Scalar(runtime);

            return glob.Scalar;
        }

        public P5Array GetArray(Runtime runtime, string name, bool create)
        {
            var glob = GetGlob(runtime, name, true);
            P5Array array;
            if ((array = glob.Array) == null && create)
                array = glob.Array = new P5Array(runtime);

            return array;
        }

        public P5Hash GetHash(Runtime runtime, string name, bool create)
        {
            var glob = GetGlob(runtime, name, true);
            P5Hash hash;
            if ((hash = glob.Hash) == null && create)
                hash = glob.Hash = new P5Hash(runtime);

            return hash;
        }

        public P5Handle GetHandle(Runtime runtime, string name, bool create)
        {
            var glob = GetGlob(runtime, name, true);
            P5Handle handle;
            if ((handle = glob.Handle) == null && create)
                handle = glob.Handle = new P5Handle(runtime, null, null);

            return handle;
        }

        public P5Typeglob GetGlob(Runtime runtime, string name, bool create)
        {
            string[] packs = name.Split(separator, StringSplitOptions.None);
            P5SymbolTable st = GetPackage(runtime, packs, true, true);

            return st.GetStashGlob(runtime, packs[packs.Length - 1], create);
        }

        public P5Typeglob GetStashGlob(Runtime runtime, string name, bool create)
        {
            IP5Any value;
            if (!hash.TryGetValue(name, out value) && create)
            {
                P5Typeglob glob = new P5Typeglob(runtime);
                ApplyMagic(runtime, name, glob);
                hash.Add(name, glob);
                value = glob;
            }

            return value as P5Typeglob;
        }

        public P5Code GetCode(Runtime runtime, string name, bool create)
        {
            P5Typeglob glob = GetGlob(runtime, name, true);
            P5Code code;
            if ((code = glob.Code) == null && create)
                code = glob.Code = new P5Code(name);

            return code;
        }

        public P5Code GetStashCode(Runtime runtime, string name, bool create)
        {
            P5Typeglob glob = GetStashGlob(runtime, name, true);
            P5Code code;
            if ((code = glob.Code) == null && create)
                code = glob.Code = new P5Code(name);

            return code;
        }

        public void SetCode(Runtime runtime, string name, P5Code code)
        {
            P5Typeglob glob = GetGlob(runtime, name, true);
            glob.Code = code;
        }

        public P5SymbolTable GetPackage(Runtime runtime, string pack)
        {
            string[] packs = pack.Split(separator, StringSplitOptions.None);

            return GetPackage(runtime, packs, false, true);
        }

        public P5SymbolTable GetPackage(Runtime runtime, string pack,
                                        bool create)
        {
            string[] packs = pack.Split(separator, StringSplitOptions.None);

            return GetPackage(runtime, packs, false, create);
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
            P5SymbolTable current = this;
            IP5Any value;

            int last = packs.Length + (skip_last ? -1 : 0);
            int first = 0;
            if (IsMain && last > 0 && packs[0] == "main")
                first = 1;
            for (int i = first; i < last; ++i)
            {
                if (!current.hash.TryGetValue(packs[i] + "::", out value))
                {
                    if (!create)
                        return null;

                    var name = string.Join("::", packs, 0, i - first + 1);
                    P5Typeglob glob = new P5Typeglob(runtime);
                    glob.Hash = new P5SymbolTable(runtime, name);
                    current.hash.Add(packs[i] + "::", glob);
                    value = glob;
                }
                current = (value as P5Typeglob).Hash as P5SymbolTable;
            }

            return current;
        }

        public new P5Code FindMethod(Runtime runtime, string method)
        {
            var code = GetStashCode(runtime, method, false);
            if (code != null)
                return code;

            IP5Any isa;
            if (!hash.TryGetValue("ISA", out isa))
            {
                var universal = runtime.SymbolTable.Universal;

                // avoid infinite recursion when searching in UNIVERSAL
                if (this == universal)
                    return null;
                return universal.FindMethod(runtime, method);
            }

            P5Array isa_array = (isa as P5Typeglob).Array;
            if (isa_array == null)
                return null;

            foreach (var c in isa_array)
            {
                var c_str = c.AsString(runtime);
                var super = runtime.SymbolTable.GetPackage(runtime, c_str, false);
                if (super == null)
                    continue;

                code = super.FindMethod(runtime, method);
                if (code != null)
                    return code;
            }

            return null;
        }

        public bool IsDerivedFrom(Runtime runtime, P5SymbolTable parent)
        {
            if (this == parent)
                return true;

            IP5Any isa;
            if (!hash.TryGetValue("ISA", out isa))
                return parent == runtime.SymbolTable.Universal;

            var isa_array = (isa as P5Typeglob).Array;
            foreach (var e in isa_array)
            {
                var base_name = e.AsString(runtime);
                var base_stash = runtime.SymbolTable.GetPackage(runtime, base_name);

                if (base_stash == null)
                    continue;
                if (base_stash == parent || base_stash.IsDerivedFrom(runtime, parent))
                    return true;
            }

            return false;
        }

        public virtual bool IsMain {
            get { return false; }
        }

        protected readonly string[] separator = new string [] {"::"};
        protected string name;
    }

    public class P5MainSymbolTable : P5SymbolTable
    {
        public P5MainSymbolTable(Runtime runtime, string name) : base(runtime, name)
        {
            var stdout = GetStashGlob(runtime, "STDOUT", true);
            stdout.Handle = new P5Handle(runtime, null, System.Console.Out);

            var stdin = GetStashGlob(runtime, "STDIN", true);
            stdin.Handle = new P5Handle(runtime, System.Console.In, null);

            var stderr = GetStashGlob(runtime, "STDERR", true);
            stderr.Handle = new P5Handle(runtime, null, System.Console.Error);

            var dquote = GetStashGlob(runtime, "\"", true);
            dquote.Scalar = new P5Scalar(runtime, " ");

            // UNIVERSAL
            universal = GetPackage(runtime, "UNIVERSAL", true);

            var isa = universal.GetStashGlob(runtime, "isa", true);
            isa.Code = new P5NativeCode("UNIVERSAL::isa", new P5Code.Sub(WrapIsa));
        }

        private static IP5Any WrapIsa(Runtime runtime, Opcode.ContextValues context,
                                      P5ScratchPad pad, P5Array args)
        {
            var value = args.GetItem(runtime, 0) as P5Scalar;
            var parent = args.GetItem(runtime, 1);
            bool is_derived = Builtins.IsDerivedFrom(runtime, value, parent);

            return new P5Scalar(runtime, is_derived);
        }

        public override bool IsMain
        {
            get { return true; }
        }

        public P5SymbolTable Universal
        {
            get { return universal; }
        }

        private P5SymbolTable universal;
    }
}
