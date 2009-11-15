using org.mbarbon.p.values;
using Path = System.IO.Path;
using File = System.IO.File;

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

        internal static string SearchFile(Runtime runtime, string file)
        {
            string file_pb;
            if (Path.HasExtension(file))
                file_pb = Path.ChangeExtension(file, "pb");
            else
                file_pb = file;

            var inc = runtime.SymbolTable.GetOrCreateArray(runtime, "INC");
            foreach (var i in inc)
            {
                var iStr = i.AsString(runtime);
                var path = Path.Combine(iStr, file);
                var path_pb = Path.Combine(iStr, file_pb);

                if (File.Exists(path_pb))
                    return path_pb;
                // TODO can only load bytecode files for now
                if (File.Exists(path))
                    return path;
            }

            return null;
        }

        public static IP5Any DoFile(Runtime runtime,
                                    Opcode.ContextValues context,
                                    P5Scalar file)
        {
            var file_s = file.AsString(runtime);
            var path = SearchFile(runtime, file_s);

            if (path == null)
                return new P5Scalar(runtime);

            var cu = Serializer.ReadCompilationUnit(path);
            P5Code main = new Generator(runtime).Generate(null, cu);
            var ret = main.Call(runtime, context, null);

            var inc = runtime.SymbolTable.GetOrCreateHash(runtime, "INC");
            inc.SetItem(runtime, file_s, new P5Scalar(runtime, path));

            return ret;
        }

        public static IP5Any RequireFile(Runtime runtime,
                                         Opcode.ContextValues context,
                                         P5Scalar file)
        {
            var file_s = file.AsString(runtime);
            var inc = runtime.SymbolTable.GetOrCreateHash(runtime, "INC");

            if (inc.ExistsKey(runtime, file_s))
                return new P5Scalar(runtime, 1);

            var path = SearchFile(runtime, file_s);
            if (path == null)
                throw new System.Exception("File not found");

            var cu = Serializer.ReadCompilationUnit(path);
            P5Code main = new Generator(runtime).Generate(null, cu);
            var ret = main.Call(runtime, context, null);

            inc.SetItem(runtime, file_s, new P5Scalar(runtime, path));

            return ret;
        }
    }
}
