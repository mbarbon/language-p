using System.Collections.Generic;

using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class ScratchPad : List<IAny>
    {
        public ScratchPad()
        {
            Lexicals = new List<LexicalInfo>();
        }

        public ScratchPad(IEnumerable<IAny> values, List<LexicalInfo> lexicals)
            : base(values)
        {
            Lexicals = lexicals;
        }

        public static ScratchPad CreateSubPad(LexicalInfo[] lexicals,
                                              ScratchPad main)
        {
            var pad = new ScratchPad();

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

        public ScratchPad NewScope(Runtime runtime)
        {
            ScratchPad scope = new ScratchPad(this, Lexicals);

            foreach (var lex in Lexicals)
            {
                if (lex == null)
                    continue;

                if (lex.OuterIndex != -1)
                    continue;
                while (scope.Count <= lex.Index)
                    scope.Add(null);
                if (lex.Slot == Opcode.Sigil.SCALAR)
                    scope[lex.Index] = new Scalar(runtime);
                else if (lex.Slot == Opcode.Sigil.ARRAY)
                    scope[lex.Index] = new Array(runtime);
                else if (lex.Slot == Opcode.Sigil.HASH)
                    scope[lex.Index] = new Hash(runtime);
            }

            return scope;
        }

        public ScratchPad CloseOver(Runtime runtime, ScratchPad outer)
        {
            ScratchPad closure = new ScratchPad(this, Lexicals);

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

        public bool HasLexicalFromMain()
        {
            foreach (var lex in Lexicals)
                if (lex.FromMain)
                    return true;

            return false;
        }

        private List<LexicalInfo> Lexicals;
    }
}
