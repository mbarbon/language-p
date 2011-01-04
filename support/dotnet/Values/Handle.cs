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

            if (input != null)
                read_buffer = new char[BUFFER_SIZE];
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
            System.Text.StringBuilder builder = null;

            for (;;)
            {
                if (rdbuf_start < rdbuf_end)
                {
                    int newline = System.Array.IndexOf(read_buffer, '\n', rdbuf_start, rdbuf_end - rdbuf_start);

                    if (newline < 0 && rdbuf_end != BUFFER_SIZE)
                        newline = rdbuf_end - 1;

                    if (newline >= 0)
                    {
                        if (builder != null)
                        {
                            builder.Append(read_buffer, rdbuf_start, newline + 1 - rdbuf_start);

                            result = new P5Scalar(runtime, builder.ToString());
                        }
                        else
                            result = new P5Scalar(runtime, new string(read_buffer, rdbuf_start, newline + 1 - rdbuf_start));

                        rdbuf_start = newline + 1;

                        return true;
                    }

                    if (builder == null)
                        builder = new System.Text.StringBuilder(2 * BUFFER_SIZE);

                    builder.Append(read_buffer, rdbuf_start, rdbuf_end - rdbuf_start);
                }

                rdbuf_start = 0;
                rdbuf_end = input.Read(read_buffer, 0, BUFFER_SIZE);

                if (rdbuf_start == rdbuf_end)
                {
                    if (builder != null)
                    {
                        result = new P5Scalar(runtime, builder.ToString());

                        return true;
                    }
                    else
                    {
                        result = new P5Scalar(runtime);

                        return false;
                    }
                }
            }
        }

        public bool Close(Runtime runtime)
        {
            bool ok = true;

            if (input != null)
                try
                {
                    input.Close();
                }
                catch (IOException)
                {
                    ok = false;
                }

            if (output != null)
                try
                {
                    output.Close();
                }
                catch (IOException)
                {
                    ok = false;
                }

            return ok;
        }

        public virtual string ReferenceTypeString(Runtime runtime)
        {
            return "IO";
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

        private int BUFFER_SIZE = 1024;
        private TextReader input;
        private TextWriter output;
        private char[] read_buffer;
        private int rdbuf_start, rdbuf_end;
    }
}
