using org.mbarbon.p.values;
using System.Collections.Generic;
using Regex = System.Text.RegularExpressions.Regex;

namespace org.mbarbon.p.runtime
{
    public partial class Builtins
    {
        private static string find_specifier = "%([ +-0#]+)?(\\d+)?(?:\\.(\\d+))?(l|h|q|L|ll)?([csduoxefgXEGbBpniDUOF%])";
        private const int FLAGS = 1;
        private const int WIDTH = 2;
        private const int PRECISION = 3;
        private const int FORMAT = 5;

        private static string MakeFloatFormat(char specifier, int width, int precision)
        {
            if (width >= 0)
                return string.Format("{{0,{0}:{2}{1}}}", width, precision, specifier);
            else
                return string.Format("{{0:{1}{0}}}", precision, specifier);
        }

        private static string MakeIntFormat(char specifier, int width, bool zero_pad)
        {
            if (zero_pad)
                return string.Format("{{0,{0}:{1}{0}}}", width, specifier);
            else
                return string.Format("{{0,{0}:{1}}}", width, specifier);
        }

        public static P5Scalar Sprintf(Runtime runtime, P5Array args)
        {
            string format = args.GetItem(runtime, 0).AsString(runtime);
            var result = new System.Text.StringBuilder();
            int index = 1, last_pos = 0;

            for (var match = specifier.Match(format); match.Success;
                 match = specifier.Match(format, last_pos))
            {
                // append text between two format placeholders
                result.Append(format, last_pos, match.Index - last_pos);
                last_pos = match.Index + match.Length;

                char format_char = format[match.Groups[FORMAT].Index];
                bool has_width = match.Groups[WIDTH].Success;
                bool has_precision = match.Groups[PRECISION].Success;
                bool zero_pad = false;
                int width = -1, precision = -1;

                if (has_width)
                    width = System.Int32.Parse(match.Groups[WIDTH].Value);

                if (has_precision)
                    precision = System.Int32.Parse(match.Groups[PRECISION].Value);

                if (match.Groups[FLAGS].Success)
                {
                    foreach (char c in match.Groups[FLAGS].Value)
                    {
                        switch (c)
                        {
                        case '0':
                            zero_pad = true;
                            break;
                        }
                    }
                }

                switch (format_char)
                {
                case 'd':
                {
                    var value = args.GetItem(runtime, index++).AsInteger(runtime);

                    if (!has_width && !zero_pad)
                        result.Append(value);
                    else
                        result.AppendFormat(MakeIntFormat('d', width, zero_pad), value);
                    break;
                }
                case 'x':
                {
                    var value = args.GetItem(runtime, index++).AsInteger(runtime);

                    if (!has_width && !zero_pad)
                        result.AppendFormat("{0:x}", value);
                    else
                        result.AppendFormat(MakeIntFormat('x', width, zero_pad), value);
                    break;
                }
                case 's':
                {
                    var value = args.GetItem(runtime, index++).AsString(runtime);

                    if (!has_width && !zero_pad)
                        result.Append(value);
                    else
                        result.AppendFormat(MakeIntFormat('S', width, zero_pad), value);
                    break;
                }
                case 'f':
                {
                    var value = args.GetItem(runtime, index++).AsFloat(runtime);

                    if (!has_width && !zero_pad && !has_precision)
                        result.Append(value);
                    else if (!zero_pad)
                        result.AppendFormat(MakeFloatFormat('f', width, precision), value);
                    else
                    {
                        var num = string.Format(MakeFloatFormat('F', -1, precision), value);

                        result.Append('0', width - num.Length);
                        result.Append(num);
                    }

                    break;
                }
                case '%':
                    result.Append('%');
                    break;
                default:
                    throw new System.Exception(string.Format("Unhandled format character '{0:C}' in sprintf", format_char));
                }
            }

            // append trailing text
            result.Append(format, last_pos, format.Length - last_pos);

            return new P5Scalar(runtime, result.ToString());
        }

        private static Regex specifier = new Regex(find_specifier);
    }
}
