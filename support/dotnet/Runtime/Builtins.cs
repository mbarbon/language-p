using org.mbarbon.p.values;
using Path = System.IO.Path;
using File = System.IO.File;
using System.Collections.Generic;

namespace org.mbarbon.p.runtime
{
    public partial class Builtins
    {
        public static void TracePosition(string file, int line)
        {
            System.Console.WriteLine(string.Format("{0:S}:{1:D}", file, line));
        }

        public static P5Scalar Bless(Runtime runtime, P5Scalar reference, IP5Any pack)
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
            if (file.IsInteger(runtime) || file.IsFloat(runtime))
            {
                var value = file.AsFloat(runtime);
                var version = runtime.SymbolTable.GetScalar(runtime, "]", false);
                var version_f = version.AsFloat(runtime);

                if (version_f >= value)
                    return new P5Scalar(runtime, true);

                var msg = string.Format("Perl {0:F} required--this is only {1:F} stopped.", value, version_f);

                throw new P5Exception(runtime, msg);
            }

            var file_s = file.AsString(runtime);
            var inc = runtime.SymbolTable.GetHash(runtime, "INC", true);

            if (inc.ExistsKey(runtime, file_s))
                return new P5Scalar(runtime, 1);

            var path = SearchFile(runtime, file_s);
            if (path == null)
                throw new P5Exception(runtime, string.Format("Can't locate {0:S} in @INC", file_s));

            var cu = Serializer.ReadCompilationUnit(runtime, path);
            P5Code main = new Generator(runtime).Generate(null, cu);
            var ret = main.Call(runtime, context, null);

            inc.SetItem(runtime, file_s, new P5Scalar(runtime, path));

            return ret;
        }

        public static int ParseOctal(string s, int start)
        {
            int end;

            for (end = start; end < s.Length; ++end)
                if (!(s[end] >= '0' && s[end] <= '7'))
                    break;

            if (start == end)
                return 0;

            return System.Convert.ToInt32(s.Substring(start, end - start), 8);
        }

        public static int ParseHexadecimal(string s, int start)
        {
            int end;

            for (end = start; end < s.Length; ++end)
                if (!(   (s[end] >= '0' && s[end] <= '9')
                      || (s[end] >= 'a' && s[end] <= 'f')
                      || (s[end] >= 'A' && s[end] <= 'F')))
                    break;

            if (start == end)
                return 0;

            return System.Convert.ToInt32(s.Substring(start, end - start), 16);
        }

        public static int ParseBinary(string s, int start)
        {
            int end;

            for (end = start; end < s.Length; ++end)
                if (s[end] != '0' && s[end] != '1')
                    break;

            if (start == end)
                return 0;

            return System.Convert.ToInt32(s.Substring(start, end - start), 2);
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

        public static int ParseBaseInteger(string s, int start, int num_base)
        {
            int rem = s.Length - start;

            if (rem > 2)
            {
                if (s[start] == '0' && s[start + 1] == 'x')
                {
                    num_base = 16;
                    start += 2;
                }
                else if (s[start] == '0' && s[start + 1] == 'b')
                {
                    num_base = 2;
                    start += 2;
                }
            }

            if (num_base == 2)
                return ParseBinary(s, start);
            else if (num_base == 8)
                return ParseOctal(s, start);
            else if (num_base == 16)
                return ParseHexadecimal(s, start);

            return 0; // can't happen
        }

        public static P5Scalar Negate(Runtime runtime, P5Scalar value)
        {
            if (value.IsString(runtime))
            {
                string str = value.AsString(runtime);
                bool word = true;

                foreach (var c in str)
                {
                    if (!(c == '_' || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')))
                    {
                        word = false;
                        break;
                    }
                }

                if (word)
                    return new P5Scalar(runtime, "-" + str);
            }

            if (value.IsFloat(runtime))
                return new P5Scalar(runtime, -value.AsFloat(runtime));

            return new P5Scalar(runtime, -value.AsInteger(runtime));
        }

        public static P5Scalar JoinList(Runtime runtime, P5Array array)
        {
            var iter = array.GetEnumerator();
            var res = new System.Text.StringBuilder();
            bool first = true;

            iter.MoveNext();
            var sep = iter.Current.AsString(runtime);

            while (iter.MoveNext())
            {
                if (!first)
                    res.Append(sep);
                first = false;
                res.Append(iter.Current.AsString(runtime));
            }

            return new P5Scalar(runtime, res.ToString());
        }

        public static P5List SplitSpaces(Runtime runtime, IP5Any value)
        {
            var str = value.AsString(runtime);
            var res = new P5List(runtime);
            int start = 0, curr = 0;

            for ( ; curr < str.Length; )
            {
                for ( ; curr < str.Length && char.IsWhiteSpace(str[curr]); ++curr)
                    ;
                start = curr;
                if (start == str.Length)
                    break;
                for ( ; curr < str.Length && !char.IsWhiteSpace(str[curr]); ++curr)
                    ;

                res.Push(runtime, new P5Scalar(runtime, str.Substring(start, curr - start)));
            }

            return res;
        }

        public static IP5Any Warn(Runtime runtime, P5Array args)
        {
            // TODO handle empty argument list when $@ is set and when it is not

            var message = new System.Text.StringBuilder();

            for (var it = args.GetEnumerator(runtime); it.MoveNext(); )
                message.Append(it.Current.AsString(runtime));

            if (message.Length > 0 && message[message.Length - 1] != '\n')
                message.Append(string.Format(" at {0:S} line {1:D}.\n",
                                             runtime.File, runtime.Line));

            var stderr = runtime.SymbolTable.GetGlob(runtime, "STDERR", true);

            stderr.Handle.Write(runtime, message.ToString());

            return new P5Scalar(runtime, 1);
        }

        public static P5Exception Die(Runtime runtime, P5Array args)
        {
            int argc = args.GetCount(runtime);

            if (argc == 1)
            {
                var s = args.GetItem(runtime, 0) as P5Scalar;

                if (s.IsReference(runtime))
                    return new P5Exception(runtime, s);
            }

            string message;
            if (argc == 0)
            {
                var exc = runtime.SymbolTable.GetStashScalar(runtime, "@", true);

                if (exc.IsDefined(runtime))
                    message = exc.AsString(runtime) + "\t...propagated";
                else
                    message = "Died";
            }
            else
            {
                var t = new System.Text.StringBuilder();
                foreach (var e in args)
                    t.Append(e.AsString(runtime));
                message = t.ToString();
            }

            return new P5Exception(runtime, message);
        }

        public static P5Typeglob SymbolicReference(Runtime runtime, string name, bool create)
        {
            // TODO strict check

            if (name.IndexOf("::") == -1 && name.IndexOf("'") == -1)
            {
                name = runtime.Package + "::" + name;
            }

            // TODO must handle punctuation variables and other special cases
            var glob = runtime.SymbolTable.GetGlob(runtime, name, create);

            return glob;
        }

        public static P5Typeglob SymbolicReferenceGlob(Runtime runtime, IP5ScalarBody any, bool create)
        {
            string name = any.AsString(runtime);
            return SymbolicReference(runtime, name, create);
        }

        public static P5Scalar SymbolicReferenceScalar(Runtime runtime, IP5ScalarBody any, bool create)
        {
            string name = any.AsString(runtime);
            var glob = SymbolicReference(runtime, name, create);

            if (glob == null)
                return null;
            if (glob.Scalar != null || !create)
                return glob.Scalar;

            return glob.Scalar = new P5Scalar(runtime);
        }

        public static P5Array SymbolicReferenceArray(Runtime runtime, IP5ScalarBody any, bool create)
        {
            string name = any.AsString(runtime);
            var glob = SymbolicReference(runtime, name, create);

            if (glob == null)
                return null;
            if (glob.Array != null || !create)
                return glob.Array;

            return glob.Array = new P5Array(runtime);
        }

        public static P5Code SymbolicReferenceCode(Runtime runtime, IP5ScalarBody any, bool create)
        {
            string name = any.AsString(runtime);
            var glob = SymbolicReference(runtime, name, create);

            if (glob == null)
                return null;
            if (glob.Code != null || !create)
                return glob.Code;

            return glob.Code = new P5Code(name);
        }

        public static P5Handle SymbolicReferenceHandle(Runtime runtime, IP5ScalarBody any, bool create)
        {
            string name = any.AsString(runtime);
            var glob = SymbolicReference(runtime, name, create);

            if (glob == null)
                return null;

            return glob.Handle;
        }

        public static P5Hash SymbolicReferenceHash(Runtime runtime, IP5ScalarBody any, bool create)
        {
            string name = any.AsString(runtime);

            if (name.EndsWith("::"))
            {
                var pack = runtime.SymbolTable.GetPackage(runtime, name.Substring(0, name.Length - 2), create);

                return pack;
            }

            var glob = SymbolicReference(runtime, name, create);

            if (glob == null)
                return null;
            if (glob.Hash != null || !create)
                return glob.Hash;

            return glob.Hash = new P5Hash(runtime);
        }

        public static IP5Any LocalizeArrayElement(Runtime runtime, IP5Array array, IP5Any index, ref SavedValue state)
        {
            int int_index = array.GetItemIndex(runtime, index.AsInteger(runtime), true);
            var saved = array.LocalizeElement(runtime, int_index);

            state.container = array;
            state.int_key = int_index;
            state.value = saved;

            return array.GetItem(runtime, int_index);
        }

        public static void RestoreArrayElement(Runtime runtime, ref SavedValue state)
        {
            if (state.container == null)
                return;

            (state.container as IP5Array).RestoreElement(runtime, state.int_key, state.value);
            state.container = null;
            state.str_key = null;
            state.value = null;
        }

        public static IP5Any LocalizeHashElement(Runtime runtime, P5Hash hash, IP5Any index, ref SavedValue state)
        {
            string str_index = index.AsString(runtime);
            var saved = hash.LocalizeElement(runtime, str_index);
            var new_value = new P5Scalar(runtime);

            state.container = hash;
            state.str_key = str_index;
            state.value = saved;

            hash.SetItem(runtime, str_index, new_value);

            return new_value;
        }

        public static void RestoreHashElement(Runtime runtime, ref SavedValue state)
        {
            if (state.container == null)
                return;

            (state.container as P5Hash).RestoreElement(runtime, state.str_key, state.value);
            state.container = null;
            state.str_key = null;
            state.value = null;
        }

        public static P5Range MakeRange(Runtime runtime, IP5Any start, IP5Any end)
        {
            // TODO handle string range
            return new P5Range(runtime, start.AsInteger(runtime), end.AsInteger(runtime));
        }

        public static IP5Regex CompileRegex(Runtime runtime, P5Scalar value, int flags)
        {
            if (value.IsReference(runtime))
            {
                var rx = value.DereferenceRegex(runtime);

                if (rx != null)
                    return rx;
            }

            if (runtime.NativeRegex)
                return new NetRegex(value.AsString(runtime));
            else
                throw new System.Exception("P5: Needs compiler to recompile string expression");
        }

        public static int Transliterate(Runtime runtime, P5Scalar scalar,
                                        string match, string replacement,
                                        int flags)
        {
            bool complement = (flags & Opcode.FLAG_RX_COMPLEMENT) != 0;
            bool delete = (flags & Opcode.FLAG_RX_DELETE) != 0;
            bool squeeze = (flags & Opcode.FLAG_RX_SQUEEZE) != 0;
            var s = scalar.AsString(runtime);
            int count = 0, last_r = -1;
            var new_str = new System.Text.StringBuilder();

            for (int i = 0; i < s.Length; ++i)
            {
                int idx = match.IndexOf(s[i]);
                int replace = s[i];

                if (idx == -1 && complement)
                {
                    if (delete)
                        replace = -1;
                    else if (replacement.Length > 0)
                        replace = replacement[replacement.Length - 1];

                    if (last_r == replace && squeeze)
                        replace = -1;
                    else
                        last_r = replace;

                    count += 1;
                }
                else if (idx != -1 && !complement)
                {
                    if (idx >= replacement.Length && delete)
                        replace = -1;
                    else if (idx >= replacement.Length)
                        replace = replacement[replacement.Length - 1];
                    else if (idx < replacement.Length)
                        replace = replacement[idx];

                    if (last_r == replace && squeeze)
                        replace = -1;
                    else
                        last_r = replace;

                    count += 1;
                }
                else
                    last_r = -1;

                if (replace != -1)
                    new_str.Append((char)replace);
            }

            scalar.SetString(runtime, new_str.ToString());

            return count;
        }

        public static P5Scalar QuoteMeta(Runtime runtime, IP5Any value)
        {
            var t = new System.Text.StringBuilder();

            foreach (char c in value.AsString(runtime))
            {
                if (!char.IsLetterOrDigit(c) && c != '_')
                    t.Append('\\');

                t.Append(c);
            }

            return new P5Scalar(runtime, t.ToString());
        }

        public static bool IsDerivedFrom(Runtime runtime, P5Scalar value, IP5Any pack)
        {
            P5SymbolTable stash = value.BlessedReferenceStash(runtime);

            if (stash == null)
                stash = runtime.SymbolTable.GetPackage(runtime, value.AsString(runtime), false);

            string pack_name = pack.AsString(runtime);
            P5SymbolTable parent = runtime.SymbolTable.GetPackage(runtime, pack_name, false);

            if (parent == null || stash == null)
                return false;

            return stash.IsDerivedFrom(runtime, parent);
        }

        public static IP5Any HashEach(Runtime runtime, Opcode.ContextValues cxt, P5Hash hash)
        {
            P5Scalar key, value;

            if (hash.NextKey(runtime, out key, out value))
            {
                if (cxt == Opcode.ContextValues.SCALAR)
                    return key;
                else
                    return new P5List(runtime, key, value);
            }
            else
            {
                if (cxt == Opcode.ContextValues.SCALAR)
                    return new P5Scalar(runtime);
                else
                    return new P5List(runtime);
            }
        }

        public static IP5Any Reverse(Runtime runtime, Opcode.ContextValues context,
                                     P5Array args)
        {
            if (context == Opcode.ContextValues.LIST)
                return args.Reversed(runtime);

            int count = args.GetCount(runtime);
            char[] value;

            if (count == 0)
                value = runtime.SymbolTable.GetStashScalar(runtime, "_", true).AsString(runtime).ToCharArray();
            else if (count == 1)
                value = args.GetItem(runtime, 0).AsString(runtime).ToCharArray();
            else
            {
                var t = new System.Text.StringBuilder();

                foreach (var i in args)
                    t.Append(i.AsString(runtime));

                value = t.ToString().ToCharArray();
            }

            // TODO does not handle UCS-4
            System.Array.Reverse(value);

            return new P5Scalar(runtime, new string(value));
        }

        public static IP5Any ArraySplice(Runtime runtime, IP5Array array,
                                         IP5Any offset, IP5Any count)
        {
            int start, length, max = array.GetCount(runtime);

            if (offset == null)
                start = 0;
            else
                start = offset.AsInteger(runtime);
            if (start < 0)
                start = max + start;

            if (count == null)
                length = max - start;
            else
                length = count.AsInteger(runtime);
            if (length < 0)
                length = max + length - start;

            return array.Splice(runtime, start, length);
        }

        public static IP5Any ArrayReplace(Runtime runtime, IP5Array array,
                                          IP5Any offset, IP5Any count,
                                          params IP5Any[] values)
        {
            int start = offset.AsInteger(runtime);
            int length = count.AsInteger(runtime);
            int max = array.GetCount(runtime);

            if (start < 0)
                start = max + start;
            if (length < 0)
                length = max + length - start;

            return array.Replace(runtime, start, length, values);
        }

        public static P5Scalar Oct(Runtime runtime, P5Scalar value)
        {
            var str = value.AsString(runtime);
            int start;

            for (start = 0; start < str.Length; ++start)
                if (!char.IsWhiteSpace(str[start]))
                    break;

            // TODO warn about invalid octal digit
            return new P5Scalar(runtime, ParseBaseInteger(str, start, 8));
        }

        public static P5Scalar Hex(Runtime runtime, P5Scalar value)
        {
            var str = value.AsString(runtime);

            // TODO warn about invalid hexadecimal digits
            return new P5Scalar(runtime, ParseBaseInteger(str, 0, 16));
        }

        public static P5Scalar Ord(Runtime runtime, IP5Any value)
        {
            var s = value.AsString(runtime);

            return new P5Scalar(runtime, s.Length > 0 ? (int)s[0] : 0);
        }

        public static P5Scalar Chr(Runtime runtime, IP5Any value)
        {
            var i = value.AsInteger(runtime);

            return new P5Scalar(runtime, new string((char)i, 1));
        }

        public static P5Scalar Uppercase(Runtime runtime, IP5Any value)
        {
            var s = value.AsString(runtime).ToUpper();

            return new P5Scalar(runtime, s);
        }

        public static P5Scalar Lowercase(Runtime runtime, IP5Any value)
        {
            var s = value.AsString(runtime).ToLower();

            return new P5Scalar(runtime, s);
        }

        public static P5Scalar Index(Runtime runtime, IP5Any value,
                                     IP5Any substr, int start)
        {
            var str = value.AsString(runtime);
            var sub = substr.AsString(runtime);

            if (start < 0)
                start = 0;
            if (start > str.Length)
                start = str.Length;

            return new P5Scalar(runtime, str.IndexOf(sub, start));
        }

        public static void AddOverload(Runtime runtime, string pack_name,
                                       P5Array args)
        {
            var overloads = new Overloads();
            var pack = runtime.SymbolTable.GetPackage(runtime, pack_name, true);

            for (int i = 0; i < args.GetCount(runtime); i += 2)
            {
                string key = args.GetItem(runtime, i).AsString(runtime);
                var value = args.GetItem(runtime, i + 1);

                overloads.AddOperation(runtime, key, value);
            }

            pack.SetOverloads(overloads);
        }

        public static bool IsOverloaded(Runtime runtime, IP5Any value,
                                        out Overloads overloads)
        {
            overloads = null;
            var scalar = value as P5Scalar;

            return scalar == null ? false : IsOverloaded(runtime, scalar,
                                                         out overloads);
        }

        public static bool IsOverloaded(Runtime runtime, P5Scalar scalar,
                                        out Overloads overloads)
        {
            overloads = null;

            if (!scalar.IsReference(runtime))
                return false;

            var stash = scalar.Dereference(runtime).Blessed(runtime);
            if (stash == null)
                return false;

            overloads = stash.Overloads;

            return stash.HasOverloading;
        }

        public static P5Scalar CallOverload(Runtime runtime, OverloadOperation op,
                                            P5Scalar left, IP5Any right)
        {
            Overloads oleft, oright;

            if (   !IsOverloaded(runtime, left, out oleft)
                && !IsOverloaded(runtime, right, out oright))
                return null;

            Overloads overload = oleft ?? oright;

            return overload.CallOperation(runtime, op, left, right,
                                          overload == oright);
        }

        public static P5Scalar CallOverloadInverted(Runtime runtime, OverloadOperation op,
                                                    P5Scalar left, IP5Any right)
        {
            Overloads oright;

            if (!IsOverloaded(runtime, right, out oright))
                return null;

            return oright.CallOperation(runtime, op, left, right, true);
        }

        public static P5Scalar AddScalarsAssign(Runtime runtime, P5Scalar left, IP5Any right)
        {
            return AddScalars(runtime, left, left, right);
        }

        public static P5Scalar AddScalars(Runtime runtime, P5Scalar res, IP5Any left, IP5Any right)
        {
            // TODO handle integer addition and integer -> float promotion
            res.SetFloat(runtime, left.AsFloat(runtime) + right.AsFloat(runtime));
            return res;
        }

        public static P5Scalar SubtractScalarsAssign(Runtime runtime, P5Scalar left, IP5Any right)
        {
            return SubtractScalars(runtime, left, left, right);
        }

        public static P5Scalar SubtractScalars(Runtime runtime, P5Scalar res, IP5Any left, IP5Any right)
        {
            // TODO handle integer addition and integer -> float promotion
            res.SetFloat(runtime, left.AsFloat(runtime) - right.AsFloat(runtime));

            return res;
        }

        public static P5Scalar MultiplyScalarsAssign(Runtime runtime, P5Scalar left, IP5Any right)
        {
            return MultiplyScalars(runtime, left, left, right);
        }

        public static P5Scalar MultiplyScalars(Runtime runtime, P5Scalar res, IP5Any left, IP5Any right)
        {
            // TODO handle integer addition and integer -> float promotion
            res.SetFloat(runtime, left.AsFloat(runtime) * right.AsFloat(runtime));

            return res;
        }

        public static P5Scalar DivideScalarsAssign(Runtime runtime, P5Scalar left, IP5Any right)
        {
            return DivideScalars(runtime, left, left, right);
        }

        public static P5Scalar DivideScalars(Runtime runtime, P5Scalar res, IP5Any left, IP5Any right)
        {
            // TODO handle integer addition and integer -> float promotion
            res.SetFloat(runtime, left.AsFloat(runtime) / right.AsFloat(runtime));

            return res;
        }

        public static P5Scalar LeftShiftScalarsAssign(Runtime runtime, P5Scalar left, IP5Any right)
        {
            return LeftShiftScalars(runtime, left, left, right);
        }

        public static P5Scalar LeftShiftScalars(Runtime runtime, P5Scalar res, IP5Any left, IP5Any right)
        {
            res.SetInteger(runtime, left.AsInteger(runtime) << right.AsInteger(runtime));

            return res;
        }

        public static P5Scalar RightShiftScalarsAssign(Runtime runtime, P5Scalar left, IP5Any right)
        {
            return RightShiftScalars(runtime, left, left, right);
        }

        public static P5Scalar RightShiftScalars(Runtime runtime, P5Scalar res, IP5Any left, IP5Any right)
        {
            res.SetInteger(runtime, left.AsInteger(runtime) >> right.AsInteger(runtime));

            return res;
        }
    }
}
