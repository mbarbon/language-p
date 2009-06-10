using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{    
    public class P5Typeglob
    {
        public P5Typeglob(Runtime runtime)
        {
            body = new P5TypeglobBody(runtime);
        }

        public P5Scalar Scalar
        {
            get { return body.Scalar; }
            set { body.Scalar = value; }
        }

        public P5Array Array
        {
            get { return body.Array; }
            set { body.Array = value; }
        }

        public P5Hash Hash
        {
            get { return body.Hash; }
            set { body.Hash = value; }
        }

        public P5Handle Handle
        {
            get { return body.Handle; }
            set { body.Handle = value; }
        }

        public P5Code Code
        {
            get { return body.Code; }
            set { body.Code = value; }
        }

        private P5TypeglobBody body;
    }

    public class P5TypeglobBody
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

        private P5Scalar scalar;
        private P5Array array;
        private P5Hash hash;
        private P5Handle handle;
        private P5Code code;
    }
}
