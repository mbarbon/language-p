using org.mbarbon.p.runtime;
using org.mbarbon.p.values;

namespace org.mbarbon.p.values
{
    public class Code : IReferrable
    {       
        public Code(System.Delegate code, bool main)
        {
            subref = (Sub)code;
            scratchpad = null;
            is_main = main;
        }

        public IAny Call(Runtime runtime, Opcode.Context context, Array args)
        {
            ScratchPad pad = scratchpad;
            if (scratchpad != null && !is_main)
                pad = scratchpad.NewScope(runtime);

            return subref(runtime, context, pad, args);
        }

        public bool HasLexicalFromMain()
        {
            return scratchpad != null && scratchpad.HasLexicalFromMain();
        }

        public void NewScope(Runtime runtime)
        {
            if (scratchpad != null)
                scratchpad = scratchpad.NewScope(runtime);
        }

        public ScratchPad ScratchPad
        {
            get { return scratchpad; }
            set { scratchpad = value; }
        }

        public delegate IAny Sub(Runtime runtime, Opcode.Context context,
                                 ScratchPad pad, Array args);

        private Sub subref;
        private ScratchPad scratchpad;
        private bool is_main;
    }
}
