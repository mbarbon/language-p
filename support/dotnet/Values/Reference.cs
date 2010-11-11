using Runtime = org.mbarbon.p.runtime.Runtime;
using Regex = org.mbarbon.p.runtime.Regex;

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
            var rx = referred as Regex;

            // TODO use overloading
            if (rx != null)
                return rx.Original;

            return "SOMETHING";
        }

        public virtual int AsInteger(Runtime runtime)
        {
            return -1;
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

        public virtual P5Scalar ReferenceType(Runtime runtime)
        {
            if (referred.IsBlessed(runtime))
                return new P5Scalar(runtime, referred.Blessed(runtime).GetName(runtime));
            if (referred as P5Scalar != null)
                return new P5Scalar(runtime, "SCALAR");
            if (referred as P5Array != null)
                return new P5Scalar(runtime, "ARRAY");
            if (referred as P5Hash != null)
                return new P5Scalar(runtime, "HASH");
            if (referred as P5Typeglob != null)
                return new P5Scalar(runtime, "GLOB");
            if (referred as P5Code != null)
                return new P5Scalar(runtime, "CODE");

            // TODO use package for blessed values
            return new P5Scalar(runtime);
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

        public virtual int GetPos(Runtime runtime)
        {
            return pos;
        }

        public virtual void SetPos(Runtime runtime, int p)
        {
            pos = p;
        }

        internal IP5Referrable Referred
        {
            get
            {
                return referred;
            }
        }

        private int pos = -1;
        private IP5Referrable referred;
    }
}
