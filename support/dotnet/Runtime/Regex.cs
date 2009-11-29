using org.mbarbon.p.values;
using System.Collections.Generic;
using SerializableAttribute = System.SerializableAttribute;

namespace org.mbarbon.p.runtime
{
    [Serializable]
    public struct RxQuantifier
    {
        public RxQuantifier(int min, int max, bool greedy, int to)
        {
            MinCount = min;
            MaxCount = max;
            IsGreedy = greedy;
            To = to;
        }

        public int MinCount, MaxCount;
        public int To;
        public bool IsGreedy;
    }

    public struct RxState
    {
        public RxState(int pos, int target, int group)
        {
            Pos = pos;
            Target = target;
            Group = group;
        }

        public int Pos;
        public int Target;
        public int Group;
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
        public int Pos;
        public List<RxGroup> Groups;
        public List<RxState> States;
        public List<int> StateBacktrack;
        public bool Matched;
    }

    [Serializable]
    public class Regex
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

        public Regex(Op[] ops, int[] targets, string[] exact,
                     RxQuantifier[] quantifiers)
        {
            Ops = ops;
            Targets = targets;
            Exact = exact;
            Quantifiers = quantifiers;
        }

        public int Backtrack(ref RxContext cxt)
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

                    // TODO restore capture groups

                    return index;
                }
            }

            if (cxt.StateBacktrack.Count > 0)
            {
                int btIdx = cxt.StateBacktrack[cxt.StateBacktrack.Count - 1];

                cxt.StateBacktrack.RemoveAt(cxt.StateBacktrack.Count - 1);
                cxt.States.RemoveRange(btIdx, cxt.States.Count - btIdx);
                cxt.Groups.RemoveAt(cxt.Groups.Count - 1);

                return Backtrack(ref cxt);
            }
            else
            {
                cxt.Matched = false;

                return -1;
            }
        }

        public bool Match(Runtime runtime, IP5Any value)
        {
            string str = value.AsString(runtime);

            for (int i = 0; i < str.Length; ++i)
            {
                bool matched = MatchAt(runtime, str, i);

                if (matched)
                    return matched;
            }

            return false;
        }

        public bool MatchAt(Runtime runtime, string str, int pos)
        {
            int len = str.Length;
            RxContext cxt;

            cxt.Pos = pos;
            cxt.Groups = new List<RxGroup>();
            cxt.States = new List<RxState>();
            cxt.StateBacktrack = new List<int>();
            cxt.Matched = false;

            for (int index = 0; index >= 0;)
            {
                switch (Ops[index].Number)
                {
                case Opcode.OpNumber.OP_RX_START_MATCH:
                    // do nothing for now
                    ++index;
                    break;
                case Opcode.OpNumber.OP_RX_EXACT:
                {
                    var s = Exact[Ops[index].Index];

                    if (   cxt.Pos + s.Length > len
                        || string.Compare(str, cxt.Pos, s, 0, s.Length) != 0)
                        index = Backtrack(ref cxt);
                    else
                    {
                        cxt.Pos += s.Length;
                        ++index;
                    }

                    break;
                }
                case Opcode.OpNumber.OP_RX_START_SPECIAL:
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
                case Opcode.OpNumber.OP_RX_QUANTIFIER:
                {
                    var group = cxt.Groups[cxt.Groups.Count - 1];
                    var quant = Quantifiers[Ops[index].Index];
                    int lastMatch = group.LastMatch;

                    ++index;
                    group.Count += 1;
                    group.LastMatch = cxt.Pos;

                    // TODO end capture

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

                    // TODO save subgroups

                    if (group.Count == 0 && quant.MinCount > 0)
                    {
                        // force failure on backtrack
                        var st = new RxState(cxt.Pos, -1, -1
                                             /* TODO saved groups here */);

                        cxt.States.Add(st);
                    }
                    else if (group.Count >= quant.MinCount)
                    {
                        var st = new RxState(cxt.Pos, index, cxt.Groups.Count - 1
                                             /* TODO saved groups here */);

                        cxt.States.Add(st);
                    }

                    cxt.Groups[cxt.Groups.Count - 1] = group;

                    // if nongreedy, match at least min
                    if (!quant.IsGreedy && group.Count >= quant.MinCount)
                    {
                        // it seems that popping the group is not needed
                        cxt.Groups.RemoveAt(cxt.Groups.Count - 1);
                        break;
                    }

                    // TODO start capture

                    index = Targets[quant.To];
                    break;
                }
                case Opcode.OpNumber.OP_RX_ACCEPT:
                {
                    // TODO null-out unclosed groups
                    // TODO return captures and end pos

                    cxt.Matched = true;
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

            return cxt.Matched;
        }

        Op[] Ops;
        string[] Exact;
        int[] Targets;
        RxQuantifier[] Quantifiers;
    }
}
