using org.mbarbon.p.values;

namespace org.mbarbon.p.runtime
{
    public partial class Builtins
    {
        public static P5Scalar BitNot(Runtime runtime, P5Scalar value)
        {
            if (value.IsString(runtime))
            {
                string svalue = value.AsString(runtime);
                var t = new System.Text.StringBuilder(svalue);;

                for (int i = 0; i < svalue.Length; ++i)
                    t[i] = (char)(~t[i] & 0xff); // only ASCII for now

                return new P5Scalar(runtime, t.ToString());
            }
            else
            {
                // TODO take into account signed/unsigned?
                return new P5Scalar(runtime, ~value.AsInteger(runtime));
            }
        }

        public static P5Scalar BitOrAssign(Runtime runtime,
                                           P5Scalar a, P5Scalar b)
        {
            return BitOr(runtime, a, a, b);
        }

        public static P5Scalar BitOr(Runtime runtime, P5Scalar res,
                                     P5Scalar a, P5Scalar b)
        {
            if (a.IsString(runtime) && b.IsString(runtime))
            {
                string sa = a.AsString(runtime), sb = b.AsString(runtime);
                System.Text.StringBuilder t;

                if (sa.Length > sb.Length)
                {
                    t = new System.Text.StringBuilder(sa);

                    for (int i = 0; i < sb.Length; ++i)
                        t[i] |= sb[i];
                }
                else
                {
                    t = new System.Text.StringBuilder(sb);

                    for (int i = 0; i < sa.Length; ++i)
                        t[i] |= sa[i];
                }

                res.SetString(runtime, t.ToString());
            }
            else
            {
                // TODO take into account signed/unsigned?
                res.SetInteger(runtime, a.AsInteger(runtime) | b.AsInteger(runtime));
            }

            return res;
        }

        public static P5Scalar BitXorAssign(Runtime runtime,
                                            P5Scalar a, P5Scalar b)
        {
            return BitXor(runtime, a, a, b);
        }

        public static P5Scalar BitXor(Runtime runtime, P5Scalar res,
                                      P5Scalar a, P5Scalar b)
        {
            if (a.IsString(runtime) && b.IsString(runtime))
            {
                string sa = a.AsString(runtime), sb = b.AsString(runtime);
                System.Text.StringBuilder t;

                if (sa.Length > sb.Length)
                {
                    t = new System.Text.StringBuilder(sa);

                    for (int i = 0; i < sb.Length; ++i)
                        t[i] ^= sb[i];
                }
                else
                {
                    t = new System.Text.StringBuilder(sb);

                    for (int i = 0; i < sa.Length; ++i)
                        t[i] ^= sa[i];
                }

                res.SetString(runtime, t.ToString());
            }
            else
            {
                // TODO take into account signed/unsigned?
                res.SetInteger(runtime, a.AsInteger(runtime) ^ b.AsInteger(runtime));
            }

            return res;
        }

        public static P5Scalar BitAndAssign(Runtime runtime,
                                            P5Scalar a, P5Scalar b)
        {
            return BitAnd(runtime, a, a, b);
        }

        public static P5Scalar BitAnd(Runtime runtime, P5Scalar res,
                                      P5Scalar a, P5Scalar b)
        {
            if (a.IsString(runtime) && b.IsString(runtime))
            {
                string sa = a.AsString(runtime), sb = b.AsString(runtime);
                System.Text.StringBuilder t;

                if (sa.Length > sb.Length)
                {
                    t = new System.Text.StringBuilder(sa);

                    for (int i = 0; i < sb.Length; ++i)
                        t[i] &= sb[i];
                }
                else
                {
                    t = new System.Text.StringBuilder(sb);

                    for (int i = 0; i < sa.Length; ++i)
                        t[i] &= sa[i];
                }

                res.SetString(runtime, t.ToString());
            }
            else
            {
                // TODO take into account signed/unsigned?
                res.SetInteger(runtime, a.AsInteger(runtime) & b.AsInteger(runtime));
            }

            return res;
        }
    }
}
