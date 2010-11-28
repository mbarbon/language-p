using System.Collections.Generic;

using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class P5ScratchPad : List<IP5Any>
    {
        public P5ScratchPad()
        {
            Lexicals = new List<LexicalInfo>();
        }

        public P5ScratchPad(IEnumerable<IP5Any> values, List<LexicalInfo> lexicals)
            : base(values)
        {
            Lexicals = lexicals;
        }

        public static P5ScratchPad CreateSubPad(LexicalInfo[] lexicals,
                                                P5ScratchPad main)
        {
            var pad = new P5ScratchPad();

            foreach (var lex in lexicals)
            {
                if (!lex.InPad)
                    continue;
                pad.AddValue(lex);

                if (lex.FromMain)
                {
                    while (pad.Count <= lex.Index)
                        pad.Add(null);
                    pad[lex.Index] = main[lex.OuterIndex];
                }
            }

            return pad;
        }

        public void AddValue(LexicalInfo info)
        {
            while (Lexicals.Count <= info.Index)
                Lexicals.Add(null);
            if (Lexicals[info.Index] == null)
                Lexicals[info.Index] = info;
        }

        public P5ScratchPad NewScope(Runtime runtime)
        {
            P5ScratchPad scope = new P5ScratchPad(this, Lexicals);

            foreach (var lex in Lexicals)
            {
                if (lex == null)
                    continue;

                if (lex.OuterIndex != -1)
                    continue;
                while (scope.Count <= lex.Index)
                    scope.Add(null);
                if (lex.Slot == Opcode.Sigil.SCALAR)
                    scope[lex.Index] = new P5Scalar(runtime);
                else if (lex.Slot == Opcode.Sigil.ARRAY)
                    scope[lex.Index] = new P5Array(runtime);
                else if (lex.Slot == Opcode.Sigil.HASH)
                    scope[lex.Index] = new P5Hash(runtime);
            }

            return scope;
        }

        public P5ScratchPad CloseOver(Runtime runtime, P5ScratchPad outer)
        {
            P5ScratchPad closure = new P5ScratchPad(this, Lexicals);

            foreach (var lex in Lexicals)
            {
                if (!lex.InPad || lex.OuterIndex == -1 || lex.FromMain)
                    continue;
                while (closure.Count <= lex.Index)
                    closure.Add(null);
                closure[lex.Index] = outer[lex.OuterIndex];
            }

            return closure;
        }

        public IP5Any GetScalar(Runtime runtime, int index)
        {
            return this[index] != null ? this[index] : this[index] = new P5Scalar(runtime);
        }

        public IP5Any GetArray(Runtime runtime, int index)
        {
            return this[index] != null ? this[index] : this[index] = new P5Array(runtime);
        }

        public IP5Any GetHash(Runtime runtime, int index)
        {
            return this[index] != null ? this[index] : this[index] = new P5Hash(runtime);
        }

        private List<LexicalInfo> Lexicals;
    }
}
