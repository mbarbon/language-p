using org.mbarbon.p.values;

namespace org.mbarbon.p.runtime
{
    public class Builtins
    {
        public static P5Scalar Print(Runtime runtime, P5Handle handle, P5List args)
        {
            // wrong but works well enough for now
            for (int i = 0, m = args.GetCount(runtime); i < m; ++i)
            {
                handle.Write(runtime, args.GetItem(runtime, i), 0, -1);
            }

            return new P5Scalar(runtime, 1);
        }

        public static P5Scalar Bless(Runtime runtime, P5Scalar reference, P5Scalar pack)
        {
            var pack_str = pack.AsString(runtime);
            var stash = runtime.SymbolTable.GetOrCreatePackage(runtime, pack_str);

            reference.BlessReference(runtime, stash);

            return reference;
        }

        public static P5Scalar WantArray(Runtime runtime, Opcode.ContextValues cxt)
        {
            if (cxt == Opcode.ContextValues.VOID)
                return new P5Scalar(runtime);

            return new P5Scalar(runtime, cxt == Opcode.ContextValues.LIST);
        }
    }
}
