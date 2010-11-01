using org.mbarbon.p.values;
using Path = System.IO.Path;
using File = System.IO.File;
using System.Collections.Generic;

namespace org.mbarbon.p.runtime
{
    public class Builtins
    {
        public static P5Scalar Print(Runtime runtime, P5Handle handle, P5Array args)
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
            var stash = runtime.SymbolTable.GetPackage(runtime, pack_str, true);

            reference.BlessReference(runtime, stash);

            return reference;
        }

        public static P5Scalar WantArray(Runtime runtime, Opcode.ContextValues cxt)
        {
            if (cxt == Opcode.ContextValues.VOID)
                return new P5Scalar(runtime);

            return new P5Scalar(runtime, cxt == Opcode.ContextValues.LIST);
        }

        public static IP5Any Readline(Runtime runtime, P5Handle handle,
                                      Opcode.ContextValues cxt)
        {
            if (cxt == Opcode.ContextValues.LIST)
            {
                P5Scalar line;
                var lines = new List<IP5Any>();

                while (handle.Readline(runtime, out line))
                    lines.Add(line);

                return new P5List(runtime, lines);
            }
            else
            {
                P5Scalar line;
                handle.Readline(runtime, out line);

                return line;
            }
        }

        internal static string SearchFile(Runtime runtime, string file)
        {
            string file_pb;
            if (Path.GetExtension(file) != ".pb")
                file_pb = file + ".pb";
            else
                file_pb = file;

            var inc = runtime.SymbolTable.GetArray(runtime, "INC", true);
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

            var cu = Serializer.ReadCompilationUnit(runtime, path);
            P5Code main = new Generator(runtime).Generate(null, cu);
            var ret = main.Call(runtime, context, null);

            var inc = runtime.SymbolTable.GetHash(runtime, "INC", true);
            inc.SetItem(runtime, file_s, new P5Scalar(runtime, path));

            return ret;
        }

        public static IP5Any RequireFile(Runtime runtime,
                                         Opcode.ContextValues context,
                                         P5Scalar file)
        {
            var file_s = file.AsString(runtime);
            var inc = runtime.SymbolTable.GetHash(runtime, "INC", true);

            if (inc.ExistsKey(runtime, file_s))
                return new P5Scalar(runtime, 1);

            var path = SearchFile(runtime, file_s);
            if (path == null)
                throw new System.Exception("File not found");

            var cu = Serializer.ReadCompilationUnit(runtime, path);
            P5Code main = new Generator(runtime).Generate(null, cu);
            var ret = main.Call(runtime, context, null);

            inc.SetItem(runtime, file_s, new P5Scalar(runtime, path));

            return ret;
        }

        public static int ParseInteger(string s)
        {
            if (s.Length == 0)
                return 0;
            if (s[0] != '-' && !char.IsDigit(s[0]) && !char.IsWhiteSpace(s[0]))
                return 0;

            // TODO this does not work for " 123", "-1_234", "12abc"
            return int.Parse(s);
        }

        public static P5Scalar BitOr(Runtime runtime, P5Scalar a, P5Scalar b)
        {
            if (a.IsString(runtime) && b.IsString(runtime))
            {
                string sa = a.AsString(runtime), sb = b.AsString(runtime);
                System.Text.StringBuilder t;

                if (sa.Length > sb.Length)
                {
                    t = new System.Text.StringBuilder(sa);

                    for (int i = 0; i < sb.Length; ++i)
                        t[i] |= sb[i];
                }
                else
                {
                    t = new System.Text.StringBuilder(sb);

                    for (int i = 0; i < sa.Length; ++i)
                        t[i] |= sa[i];
                }

                return new P5Scalar(runtime, t.ToString());
            }
            else
            {
                // TODO take into account signed/unsigned?
                return new P5Scalar(runtime, a.AsInteger(runtime) | b.AsInteger(runtime));
            }
        }
    }
}
