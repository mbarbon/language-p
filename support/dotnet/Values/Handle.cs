using org.mbarbon.p.runtime;
using System.Collections.Generic;
using System.IO;

namespace org.mbarbon.p.values
{
    public class P5Handle : IP5Referrable
    {
        public P5Handle(Runtime _runtime, TextReader _input, TextWriter _output)
        {
            input = _input;
            output = _output;
        }

        public int Write(Runtime runtime, IP5Any scalar, int offset, int length)
        {
            // TODO use offset/length
            output.Write(scalar.AsString(runtime));

            return 1;
        }

        public int Write(Runtime runtime, string value)
        {
            output.Write(value);

            return 1;
        }

        public bool Readline(Runtime runtime, out P5Scalar result)
        {
            // TODO rewrite and optimize
            var line = input.ReadLine();

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

        private TextReader input;
        private TextWriter output;
    }
}
