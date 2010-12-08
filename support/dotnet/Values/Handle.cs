using org.mbarbon.p.runtime;
using System.Collections.Generic;

namespace org.mbarbon.p.values
{
    public class P5Handle : IP5Referrable
    {
        public P5Handle(Runtime runtime, System.IO.TextReader input, System.IO.TextWriter output)
        {
            Input = input;
            Output = output;
        }

        public int Write(Runtime runtime, IP5Any scalar, int offset, int length)
        {
            // TODO use offset/length
            Output.Write(scalar.AsString(runtime));

            return 1;
        }

        public int Write(Runtime runtime, string value)
        {
            Output.Write(value);

            return 1;
        }

        public bool Readline(Runtime runtime, out P5Scalar result)
        {
            // TODO rewrite and optimize
            var line = Input.ReadLine();

            if (line == null)
                result = new P5Scalar(runtime);
            else
                result = new P5Scalar(runtime, line + "\n");

            return line != null;
        }

        public virtual P5Scalar ReferenceType(Runtime runtime)
        {
            return new P5Scalar(runtime);
        }

        public virtual void Bless(Runtime runtime, P5SymbolTable stash)
        {
            throw new System.InvalidOperationException("Not a reference");
        }

        public virtual bool IsBlessed(Runtime runtime)
        {
            return false;
        }

        public virtual P5SymbolTable Blessed(Runtime runtime)
        {
            return null;
        }

        private System.IO.TextReader Input;
        private System.IO.TextWriter Output;
    }
}
