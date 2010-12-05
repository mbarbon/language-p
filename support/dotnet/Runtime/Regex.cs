using org.mbarbon.p.values;
using System.Collections.Generic;
using SerializableAttribute = System.SerializableAttribute;

namespace org.mbarbon.p.runtime
{
    [Serializable]
    public struct RxQuantifier
    {
        public RxQuantifier(int min, int max, bool greedy, int to, int group,
                            int start_subgroup, int end_subgroup)
        {
            MinCount = min;
            MaxCount = max;
            IsGreedy = greedy;
            To = to;
            Group = group;
            SubgroupStart = start_subgroup;
            SubgroupEnd = end_subgroup;
        }

        public int MinCount, MaxCount, Group;
        public int To;
        public bool IsGreedy;
        public int SubgroupStart, SubgroupEnd;
    }

    [Serializable]
    public struct RxClass
    {
        public RxClass(string exact, int flags)
        {
            Exact = exact;
            Flags = flags;
        }

        public string Exact;
        public int Flags;
    }

    public struct RxCapture
    {
        public int Start;
        public int End;
    }

    public struct RxSavedGroups
    {
        public int Start, LastOpenCapture, LastClosedCapture;
        public RxCapture[] Data;
    }

    public struct RxState
    {
        public RxState(int pos, int target, int group)
        {
            Pos = pos;
            Target = target;
            Group = group;
            Groups = new RxSavedGroups();
        }

        public int Pos;
        public int Target;
        public int Group;
        public RxSavedGroups Groups;
    }

    public struct RxGroup
    {
        public RxGroup(int lastMatch)
        {
            Count = -1;
            LastMatch = lastMatch;
        }

        public int Count;
        public int LastMatch;
    }

    public struct RxContext
    {
        public int Pos, LastOpenCapture, LastClosedCapture;
        public List<RxGroup> Groups;
        public List<RxState> States;
        public List<int> StateBacktrack;
        public RxCapture[] Captures;
        public int[] Saved;
    }

    public struct RxResult
    {
        public int Start, End;
        public RxCapture[] Captures;
        public string[] StringCaptures;
        public bool Matched;
    }

    public struct RxReplacement
    {
        public RxReplacement(string str, int st, int en)
        {
            String = str;
            Start = st;
            End = en;
        }

        public string String;
        public int Start, End;
    }

    [Serializable]
    public class P5Regex : IP5Regex
    {
        [Serializable]
        public struct Op
        {
            public Op(Opcode.OpNumber op, int index)
            {
                Number = op;
                Index = index;
            }

            public Op(Opcode.OpNumber op)
            {
                Number = op;
                Index = -1;
            }

            public Opcode.OpNumber Number;
            public int Index;
        }

        public P5Regex(Op[] ops, int[] targets, string[] exact,
                       RxQuantifier[] quantifiers, RxClass[] classes,
                       int captures, int saved, string orig)
        {
            Ops = ops;
            Targets = targets;
            Exact = exact;
            Quantifiers = quantifiers;
            Classes = classes;
            Captures = captures;
            Saved = saved;
            original = orig;
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

        private void SaveGroups(ref RxContext cxt, int start, int end,
                                bool clear, out RxSavedGroups groups)
        {
            groups.Start = start;
            groups.LastOpenCapture = cxt.LastOpenCapture;
            groups.LastClosedCapture = cxt.LastClosedCapture;
            groups.Data = new RxCapture[end - start];

            for (int i = start; i < end; ++i)
            {
                if (clear || cxt.Captures.Length <= i)
                    groups.Data[i - start].Start = groups.Data[i - start].End = -1;
                else
                {
                    groups.Data[i - start] = cxt.Captures[i];
                }
            }
        }

        private void RestoreGroups(ref RxContext cxt, ref RxSavedGroups groups)
        {
            if (groups.Data == null)
                return;

            for (int i = 0; i < groups.Data.Length; ++i)
                cxt.Captures[i + groups.Start] = groups.Data[i];

            cxt.LastOpenCapture = groups.LastOpenCapture;
            cxt.LastClosedCapture = groups.LastClosedCapture;
        }

        private int Backtrack(ref RxContext cxt)
        {
            if (cxt.States.Count > 0)
            {
                var btState = cxt.States[cxt.States.Count - 1];

                cxt.States.RemoveAt(cxt.States.Count - 1);
                cxt.Pos = btState.Pos;
                int index = btState.Target;

                if (index >= 0)
                {
                    if (btState.Group >= 0)
                        cxt.Groups.RemoveRange(btState.Group, cxt.Groups.Count - btState.Group);

                    RestoreGroups(ref cxt, ref btState.Groups);

                    return index;
                }
            }

            if (cxt.StateBacktrack.Count > 0)
            {
                int btIdx = cxt.StateBacktrack[cxt.StateBacktrack.Count - 1];

                cxt.StateBacktrack.RemoveAt(cxt.StateBacktrack.Count - 1);
                cxt.States.RemoveRange(btIdx, cxt.States.Count - btIdx);
                if (cxt.Groups.Count > 0)
                    cxt.Groups.RemoveAt(cxt.Groups.Count - 1);

                return Backtrack(ref cxt);
            }
            else
            {
                return -1;
            }
        }

        private void StartCapture(ref RxContext cxt, int group)
        {
            for (int i = cxt.LastOpenCapture + 1; i < group; ++i)
                cxt.Captures[i].Start = cxt.Captures[i].End = -1;

            cxt.Captures[group].Start = cxt.Pos;
            cxt.Captures[group].End = -1;

            if (cxt.LastOpenCapture < group)
                cxt.LastOpenCapture = group;
        }

        private void EndCapture(ref RxContext cxt, int group)
        {
            cxt.Captures[group].End = cxt.Pos;

            cxt.LastClosedCapture = group;
        }

        public IP5Any Match(Runtime runtime, IP5Any value, int flags,
                            Opcode.ContextValues cxt, ref RxResult oldState)
        {
            return P5Regex.MatchHelper(this, runtime, value, flags,
                                       cxt, ref oldState);
        }

        public static IP5Any MatchHelper(IP5Regex regex, Runtime runtime, IP5Any value, int flags,
                                   Opcode.ContextValues cxt, ref RxResult oldState)
        {
            bool match = regex.MatchString(runtime, value.AsString(runtime),
                                           -1, false, ref oldState);

            if (cxt != Opcode.ContextValues.LIST)
            {
                return new P5Scalar(runtime, match);
            }
            else if (match && runtime.LastMatch.StringCaptures.Length > 0)
            {
                var res = new IP5Any[runtime.LastMatch.StringCaptures.Length];
                for (int i = 0; i < runtime.LastMatch.StringCaptures.Length; ++i)
                    res[i] = new P5Scalar(runtime, runtime.LastMatch.StringCaptures[i]);

                return new P5List(runtime, res);
            }
            else
            {
                return new P5List(runtime, match);
            }
        }

        public IP5Any MatchGlobal(Runtime runtime, IP5Any value, int flags,
                                  Opcode.ContextValues cxt, ref RxResult oldState)
        {
            return P5Regex.MatchGlobalHelper(this, runtime, value, flags,
                                             cxt, ref oldState);
        }

        public static IP5Any MatchGlobalHelper(IP5Regex regex, Runtime runtime, IP5Any value, int flags,
                                               Opcode.ContextValues cxt, ref RxResult oldState)
        {
            var scalar = value as P5Scalar;
            bool pos_set;
            int pos = value.GetPos(runtime, out pos_set);
            string str = value.AsString(runtime);
            bool match;
            IP5Any result;

            if (cxt != Opcode.ContextValues.LIST)
            {
                match = regex.MatchString(runtime, str, pos, pos_set,
                                          ref oldState);

                result = new P5Scalar(runtime, match);

                if (scalar != null)
                {
                    if (match)
                        scalar.SetPos(runtime, runtime.LastMatch.End, false);
                    else if ((flags & Opcode.RX_KEEP) == 0)
                        scalar.UnsetPos(runtime);
                }
            }
            else
            {
                var capt = new List<IP5Any>();

                for (;;)
                {
                    match = regex.MatchString(runtime, str,
                                              pos, pos_set, ref oldState);
                    if (match)
                    {
                        if (runtime.LastMatch.StringCaptures != null)
                        {
                            foreach (var s in runtime.LastMatch.StringCaptures)
                                capt.Add(new P5Scalar(runtime, s));
                        }
                        else
                        {
                            string s = str.Substring(runtime.LastMatch.Start,
                                                     runtime.LastMatch.End - runtime.LastMatch.Start);
                            capt.Add(new P5Scalar(runtime, s));
                        }
                    }
                    else
                        break;

                    pos = runtime.LastMatch.End;
                }

                if (scalar != null)
                {
                    if ((flags & Opcode.RX_KEEP) != 0)
                        scalar.SetPos(runtime, pos, false);
                    else
                        scalar.UnsetPos(runtime);
                }

                result = new P5List(runtime, capt);
            }

            return result;
        }

        public bool MatchString(Runtime runtime, string str, int pos,
                                bool allow_zero, ref RxResult oldState)
        {
            int st = pos >= 0 ? pos : 0;

            for (int i = st; i <= str.Length; ++i)
            {
                RxResult res;
                MatchAt(runtime, str, i, out res);

                if (res.Matched)
                {
                    if (pos >= 0 && pos == res.End && !allow_zero)
                    {
                        res.Matched = false;
                        continue;
                    }

                    oldState = runtime.LastMatch;
                    runtime.LastMatch = res;

                    return true;
                }
            }

            return false;
        }

        private static bool IsWord(char c)
        {
            return char.IsLetterOrDigit(c) || c == '_';
        }

        private bool MatchAt(Runtime runtime, string str, int pos,
                             out RxResult res)
        {
            int len = str.Length;

            res.Matched = false;
            res.Start = res.End = -1;
            res.Captures = null;
            res.StringCaptures = null;

            RxContext cxt;

            cxt.Pos = pos;
            cxt.Groups = new List<RxGroup>();
            cxt.States = new List<RxState>();
            cxt.StateBacktrack = new List<int>();
            if (Captures > 0)
                cxt.Captures = new RxCapture[Captures];
            else
                cxt.Captures = null;
            if (Saved > 0)
                cxt.Saved = new int[Saved];
            else
                cxt.Saved = null;
            cxt.LastOpenCapture = cxt.LastClosedCapture = -1;

            for (int index = 0; index >= 0;)
            {
                switch (Ops[index].Number)
                {
                case Opcode.OpNumber.OP_RX_START_MATCH:
                    // do nothing for now
                    ++index;
                    break;
                case Opcode.OpNumber.OP_RX_EXACT:
                case Opcode.OpNumber.OP_RX_EXACT_I:
                {
                    var s = Exact[Ops[index].Index];
                    bool case_insensitive = Ops[index].Number == Opcode.OpNumber.OP_RX_EXACT_I;

                    if (   cxt.Pos + s.Length > len
                        || string.Compare(str, cxt.Pos, s, 0, s.Length,
                                          case_insensitive) != 0)
                        index = Backtrack(ref cxt);
                    else
                    {
                        cxt.Pos += s.Length;
                        ++index;
                    }

                    break;
                }
                case Opcode.OpNumber.OP_RX_SAVE_POS:
                {
                    cxt.Saved[Ops[index].Index] = cxt.Pos;

                    ++index;
                    break;
                }
                case Opcode.OpNumber.OP_RX_RESTORE_POS:
                {
                    cxt.Pos = cxt.Saved[Ops[index].Index];

                    ++index;
                    break;
                }
                case Opcode.OpNumber.OP_RX_ANY_NONEWLINE:
                {
                    if (cxt.Pos == len || str[cxt.Pos] == '\n')
                        index = Backtrack(ref cxt);
                    else
                    {
                        ++cxt.Pos;
                        ++index;
                    }

                    break;
                }
                case Opcode.OpNumber.OP_RX_ANY:
                {
                    if (cxt.Pos == len)
                        index = Backtrack(ref cxt);
                    else
                    {
                        ++cxt.Pos;
                        ++index;
                    }

                    break;
                }
                case Opcode.OpNumber.OP_RX_CLASS:
                {
                    var c = Classes[Ops[index].Index];

                    if (cxt.Pos < len)
                    {
                        char ch = str[cxt.Pos];

                        ++cxt.Pos;
                        ++index;

                        if (c.Exact.IndexOf(ch) >= 0)
                            break;

                        if ((c.Flags & Opcode.RX_CLASS_WORDS) != 0 && IsWord(ch))
                            break;
                        if ((c.Flags & Opcode.RX_CLASS_NOT_WORDS) != 0 && !IsWord(ch))
                            break;
                        if ((c.Flags & Opcode.RX_CLASS_DIGITS) != 0 && char.IsDigit(ch))
                            break;
                        if ((c.Flags & Opcode.RX_CLASS_NOT_DIGITS) != 0 && !char.IsDigit(ch))
                            break;
                        if ((c.Flags & Opcode.RX_CLASS_SPACES) != 0 && char.IsWhiteSpace(ch))
                            break;
                        if ((c.Flags & Opcode.RX_CLASS_NOT_SPACES) != 0 && !char.IsWhiteSpace(ch))
                            break;
                    }

                    index = Backtrack(ref cxt);
                    break;
                }
                case Opcode.OpNumber.OP_RX_BEGINNING:
                {
                    if (cxt.Pos != 0)
                        index = Backtrack(ref cxt);
                    else
                        ++index;

                    break;
                }
                case Opcode.OpNumber.OP_RX_START_GROUP:
                {
                    var grp = new RxGroup(-1);

                    cxt.Groups.Add(grp);
                    cxt.StateBacktrack.Add(cxt.States.Count);

                    index = Targets[Ops[index].Index];
                    break;
                }
                case Opcode.OpNumber.OP_RX_BACKTRACK:
                case Opcode.OpNumber.OP_RX_TRY:
                {
                    var st = new RxState(cxt.Pos, Targets[Ops[index].Index],
                                         cxt.Groups.Count);

                    cxt.States.Add(st);

                    ++index;
                    break;
                }
                case Opcode.OpNumber.OP_RX_POP_STATE:
                {
                    cxt.States.RemoveAt(cxt.States.Count - 1);

                    ++index;
                    break;
                }
                case Opcode.OpNumber.OP_RX_FAIL:
                {
                    index = Backtrack(ref cxt);
                    break;
                }
                case Opcode.OpNumber.OP_RX_QUANTIFIER:
                {
                    var group = cxt.Groups[cxt.Groups.Count - 1];
                    var quant = Quantifiers[Ops[index].Index];
                    int lastMatch = group.LastMatch;

                    ++index;
                    group.Count += 1;
                    group.LastMatch = cxt.Pos;

                    if (group.Count > 0 && quant.Group >= 0)
                        EndCapture(ref cxt, quant.Group);

                    // max repeat count
                    if (group.Count == quant.MaxCount)
                    {
                        cxt.Groups.RemoveAt(cxt.Groups.Count - 1);
                        break;
                    }

                    // zero-length match
                    if (cxt.Pos == lastMatch)
                    {
                        break;
                    }

                    RxSavedGroups gr;
                    if (group.Count == 0 || group.Count >= quant.MinCount)
                        SaveGroups(ref cxt, quant.SubgroupStart, quant.SubgroupEnd,
                                   group.Count == 0,
                                   out gr);
                    else
                        gr = new RxSavedGroups();

                    if (group.Count == 0 && quant.MinCount > 0)
                    {
                        // force failure on backtrack
                        var st = new RxState(cxt.Pos, -1, -1);
                        st.Groups = gr;

                        cxt.States.Add(st);
                    }
                    else if (quant.IsGreedy && group.Count >= quant.MinCount)
                    {
                        var st = new RxState(cxt.Pos, index, cxt.Groups.Count - 1);
                        st.Groups = gr;

                        cxt.States.Add(st);
                    }

                    cxt.Groups[cxt.Groups.Count - 1] = group;

                    // if nongreedy, match at least min
                    if (!quant.IsGreedy && group.Count >= quant.MinCount)
                    {
                        var st = new RxState(cxt.Pos, Targets[quant.To], cxt.Groups.Count);
                        st.Groups = gr;

                        cxt.States.Add(st);
                        break;
                    }

                    if (quant.Group >= 0)
                        StartCapture(ref cxt, quant.Group);

                    index = Targets[quant.To];
                    break;
                }
                case Opcode.OpNumber.OP_RX_CAPTURE_START:
                {
                    StartCapture(ref cxt, Ops[index].Index);

                    ++index;
                    break;
                }
                case Opcode.OpNumber.OP_RX_CAPTURE_END:
                {
                    EndCapture(ref cxt, Ops[index].Index);

                    ++index;
                    break;
                }
                case Opcode.OpNumber.OP_RX_ACCEPT:
                {
                    for (int i = cxt.LastOpenCapture + 1; i < Ops[index].Index; ++i)
                        cxt.Captures[i].Start = cxt.Captures[i].End = -1;

                    if (cxt.Captures != null)
                    {
                        res.StringCaptures = new string[cxt.Captures.Length];
                        for (int i = 0; i < cxt.Captures.Length; ++i)
                            if (cxt.Captures[i].End != -1)
                                res.StringCaptures[i] =
                                    str.Substring(cxt.Captures[i].Start,
                                                  cxt.Captures[i].End - cxt.Captures[i].Start);
                    }

                    res.Start = pos;
                    res.End = cxt.Pos;
                    res.Captures = cxt.Captures;
                    res.Matched = true;

                    index = -1;

                    break;
                }
                case Opcode.OpNumber.OP_JUMP:
                    index = Targets[Ops[index].Index];
                    break;
                default:
                    throw new System.Exception("PANIC: unhandled opcode " + Ops[index].Number);
                }
            }

            return res.Matched;
        }

        public static void ReplaceSubstrings(Runtime runtime, P5Scalar value,
                                             string str,
                                             List<RxReplacement> substrings)
        {
            for (int i = substrings.Count - 1; i >= 0; --i)
            {
                // TODO optimize
                str = str.Substring(0, substrings[i].Start)
                    + substrings[i].String + str.Substring(substrings[i].End);

            }

            value.Assign(runtime, new P5Scalar(runtime, str));
        }

        public string GetOriginal() { return original; }

        private Op[] Ops;
        private string[] Exact;
        private int[] Targets;
        private RxQuantifier[] Quantifiers;
        private RxClass[] Classes;
        private int Captures, Saved;
        private string original;
    }
}
