using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{
    public class P5Typeglob : P5Scalar
    {
        public P5Typeglob(Runtime runtime)
        {
            body = globBody = new P5TypeglobBody(runtime);
        }

        public P5Scalar Scalar
        {
            get { return globBody.Scalar; }
            set { globBody.Scalar = value; }
        }

        public P5Array Array
        {
            get { return globBody.Array; }
            set { globBody.Array = value; }
        }

        public P5Hash Hash
        {
            get { return globBody.Hash; }
            set { globBody.Hash = value; }
        }

        public P5Handle Handle
        {
            get { return globBody.Handle; }
            set { globBody.Handle = value; }
        }

        public P5Code Code
        {
            get { return globBody.Code; }
            set { globBody.Code = value; }
        }

        public override IP5Any Assign(Runtime runtime, IP5Any other)
        {
            var ob = other.AsScalar(runtime).Body;
            var obr = ob as P5Reference;
            var obb = ob as P5TypeglobBody;

            if (obb != null)
                body = globBody = obb;
            else if (obr != null)
            {
                var referred = obr.Referred;
                var code = referred as P5Code;
                var scalar = referred as P5Scalar;

                if (code != null)
                    globBody.Code = code;
                else if (scalar != null)
                    globBody.Scalar = scalar;
            }
            else
            {
                throw new System.NotImplementedException("Assign either glob or reference");
            }

            return this;
        }

        private P5TypeglobBody globBody;
    }

    public class P5TypeglobBody : IP5ScalarBody
    {
        public P5TypeglobBody(Runtime runtime)
        {
        }

        public P5Scalar Scalar
        {
            get { return scalar; }
            set { scalar = value; }
        }

        public P5Array Array
        {
            get { return array; }
            set { array = value; }
        }

        public P5Hash Hash
        {
            get { return hash; }
            set { hash = value; }
        }

        public P5Handle Handle
        {
            get { return handle; }
            set { handle = value; }
        }

        public P5Code Code
        {
            get { return code; }
            set { code = value; }
        }

        // IP5ScalarBody implementation
        public virtual IP5ScalarBody CloneBody(Runtime runtime)
        {
            var newBody = new P5TypeglobBody(runtime);

            newBody.scalar = scalar;
            newBody.array = array;
            newBody.hash = hash;
            newBody.handle = handle;
            newBody.code = code;

            return newBody;
        }

        public virtual string AsString(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual int AsInteger(Runtime runtime) { throw new System.NotImplementedException(); }
        public virtual double AsFloat(Runtime runtime) { throw new System.NotImplementedException(); }

        public virtual bool AsBoolean(Runtime runtime)
        {
            return true;
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            return code;
        }

        private P5Scalar scalar;
        private P5Array array;
        private P5Hash hash;
        private P5Handle handle;
        private P5Code code;
    }
}
