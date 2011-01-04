using Runtime = org.mbarbon.p.runtime.Runtime;
using IdDispenser = Microsoft.Scripting.Runtime.IdDispenser;

namespace org.mbarbon.p.values
{
    public class P5Reference : IP5ScalarBody
    {
        public P5Reference(Runtime runtime, IP5Referrable val)
        {
            referred = val;
        }

        public virtual IP5ScalarBody CloneBody(Runtime runtime)
        {
            return new P5Reference(runtime, referred);
        }

        public virtual string AsString(Runtime runtime)
        {
            var rx = referred as IP5Regex;

            // TODO use overloading
            if (rx != null)
                return rx.GetOriginal();

            return string.Format("{0:s}({1:x8})", ReferenceTypeString(runtime),
                                 IdDispenser.GetId(referred));
        }

        public virtual int AsInteger(Runtime runtime)
        {
            // TODO maybe use long everywhere
            return (int)IdDispenser.GetId(referred);
        }

        public virtual double AsFloat(Runtime runtime)
        {
            return AsInteger(runtime);
        }

        public virtual bool IsInteger(Runtime runtime) { return true; }
        public virtual bool IsString(Runtime runtime) { return true; }
        public virtual bool IsFloat(Runtime runtime) { return false; }

        public virtual bool AsBoolean(Runtime runtime)
        {
            return true;
        }

        public virtual int Length(Runtime runtime)
        {
            return AsString(runtime).Length;
        }

        internal string ReferenceTypeString(Runtime runtime)
        {
            if (referred.IsBlessed(runtime))
                return referred.Blessed(runtime).GetName(runtime);
            if (referred as P5Scalar != null)
                return "SCALAR";
            if (referred as P5Array != null)
                return "ARRAY";
            if (referred as P5Hash != null)
                return "HASH";
            if (referred as P5Typeglob != null)
                return "GLOB";
            if (referred as P5Code != null)
                return "CODE";

            // TODO use package for blessed values
            return null;
        }

        public virtual P5Scalar ReferenceType(Runtime runtime)
        {
            var s = ReferenceTypeString(runtime);

            return s == null ? new P5Scalar(runtime) : new P5Scalar(runtime, s);
        }

        public virtual P5Scalar DereferenceScalar(Runtime runtime)
        {
            P5Scalar val = referred as P5Scalar;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not a SCALAR reference");
        }

        public virtual P5Array DereferenceArray(Runtime runtime)
        {
            P5Array val = referred as P5Array;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not an ARRAY reference");
        }

        public virtual P5Hash DereferenceHash(Runtime runtime)
        {
            P5Hash val = referred as P5Hash;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not a HASH reference");
        }

        public virtual P5Typeglob DereferenceGlob(Runtime runtime)
        {
            P5Typeglob val = referred as P5Typeglob;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not a GLOB reference");
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            P5Code val = referred as P5Code;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not a CODE reference");
        }

        public virtual P5Handle DereferenceHandle(Runtime runtime)
        {
            P5Handle val = referred as P5Handle;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not a HANDLE reference");
        }

        public virtual int GetPos(Runtime runtime)
        {
            return pos;
        }

        public virtual int GetPos(Runtime runtime, out bool _pos_set)
        {
            _pos_set = pos_set;

            return pos;
        }

        public virtual void SetPos(Runtime runtime, int _pos, bool _pos_set)
        {
            pos = _pos;
            pos_set = _pos_set;
        }

        internal IP5Referrable Referred
        {
            get { return referred; }
            set { referred = value; }
        }

        private int pos = -1;
        private bool pos_set = false;
        private IP5Referrable referred;
    }
}
