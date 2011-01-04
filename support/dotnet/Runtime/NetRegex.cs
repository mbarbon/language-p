using org.mbarbon.p.values;
using SerializableAttribute = System.SerializableAttribute;

namespace org.mbarbon.p.runtime
{
    [Serializable]
    public class NetRegex : IP5Regex
    {
        public NetRegex(string _original)
        {
            original = _original;
            regex = new System.Text.RegularExpressions.Regex(_original);
        }

        public virtual void Bless(Runtime runtime, P5SymbolTable stash)
        {
            // do nothing
        }

        public virtual bool IsBlessed(Runtime runtime)
        {
            return true;
        }

        public virtual P5SymbolTable Blessed(Runtime runtime)
        {
            return runtime.SymbolTable.GetPackage(runtime, "Regexp");
        }

        public virtual string ReferenceTypeString(Runtime runtime)
        {
            return "Regexp";
        }

        public IP5Any Match(Runtime runtime, IP5Any value, int flags,
                            Opcode.ContextValues cxt, ref RxResult oldState)
        {
            return P5Regex.MatchHelper(this, runtime, value, flags,
                                       cxt, ref oldState);
        }

        public IP5Any MatchGlobal(Runtime runtime, IP5Any value, int flags,
                                  Opcode.ContextValues cxt, ref RxResult oldState)
        {
            return P5Regex.MatchGlobalHelper(this, runtime, value, flags,
                                             cxt, ref oldState);
        }

        public bool MatchString(Runtime runtime, string str, int pos,
                                bool allow_zero, ref RxResult oldState)
        {
            int st = pos >= 0 ? pos : 0;

            for (int i = st; i <= str.Length; ++i)
            {
                var match = regex.Match(str, i);

                if (match.Success)
                {
                    RxResult res;

                    if (pos >= 0 && pos == match.Index + match.Length && !allow_zero)
                    {
                        res.Matched = false;
                        continue;
                    }

                    res.Matched = match.Success;
                    res.Start = match.Index;
                    res.End = match.Index + match.Length;

                    if (match.Groups.Count > 1)
                    {
                        res.Captures = new RxCapture[match.Groups.Count - 1];
                        res.StringCaptures = new string[match.Groups.Count - 1];

                        for (int j = 0; j < res.Captures.Length; ++j)
                        {
                            var capt = match.Groups[j + 1];

                            res.Captures[j].Start = capt.Index;
                            res.Captures[j].End = capt.Index + capt.Length;
                            res.StringCaptures[j] = str.Substring(capt.Index, capt.Length);
                        }
                    }
                    else
                    {
                        res.Captures = null;
                        res.StringCaptures = null;
                    }

                    oldState = runtime.LastMatch;
                    runtime.LastMatch = res;

                    return res.Matched;
                }
            }

            return false;
        }

        public string GetOriginal() { return original; }

        System.Text.RegularExpressions.Regex regex;
        string original;
    }
}
