using System.Text;
using System.Collections.Generic;
using System.IO;
using System.Diagnostics.Contracts;

namespace Microsoft.Boogie
{
  [Immutable]
  public interface IToken
  {
    int kind { get; set; } // token kind
    string filename { get; set; } // token file
    int pos { get; set; } // token position in the source text (starting at 0)
    int col { get; set; } // token column (starting at 0)
    int line { get; set; } // token line (starting at 1)
    string /*!*/ val { get; set; } // token value
    
    string/*!*/ leadingTrivia { get; set; } // Leading trivia (comments, whitespace)
    string/*!*/ trailingTrivia { get; set; } // Trailing trivia (comments, whitespace)

    bool IsValid { get; }
  }

  [Immutable]
  public class Token : IToken
  {
    public int _kind; // token kind
    string _filename; // token file
    public int _pos; // token position in the source text (starting at 0)
    public int _col; // token column (starting at 1)
    public int _line; // token line (starting at 1)
    public string/*!*/ _trailingTrivia; // Trivia after this token attached to it (whitespace and comments)
    public string/*!*/ _leadingTrivia; // Trivia before this token attached to it

    public string /*!*/
      _val; // token value

    public Token next; // ML 2005-03-11 Tokens are kept in linked list

    public static readonly IToken /*!*/
      NoToken = new Token();

    public Token()
    {
      this._val = "anything so that it is nonnull";
    }

    public Token(int linenum, int colnum)
      : base()
    {
      this._line = linenum;
      this._col = colnum;
      this._val = "anything so that it is nonnull";
    }

    public int kind
    {
      get { return this._kind; }
      set { this._kind = value; }
    }

    public string filename
    {
      get { return this._filename; }
      set { this._filename = value; }
    }

    public int pos
    {
      get { return this._pos; }
      set { this._pos = value; }
    }

    public int col
    {
      get { return this._col; }
      set { this._col = value; }
    }

    public int line
    {
      get { return this._line; }
      set { this._line = value; }
    }

    public string /*!*/ val
    {
      get { return this._val; }
      set { this._val = value; }
    }
    
    public string /*!*/ leadingTrivia
    {
      get { return this._leadingTrivia; }
      set { this._leadingTrivia = value; }
    }
    
    public string /*!*/ trailingTrivia
    {
      get { return this._trailingTrivia; }
      set { this._trailingTrivia = value; }
    }
    
    /// <summary>
    /// Duplicates this token and removes the borrowed trivia in the original
    /// Returns a fresh "detached" token that contains the borrowed trivia
    /// Used for outer expressions to determine ranges
    /// </summary>
    /// <returns>A freshly cloned token with the borrowed leading or trailing trivia</returns>
    public Token BorrowTrivia(bool leading = false, bool trailing = false) {
      string borrowedTrailingTrivia = null;
      string borrowedLeadingTrivia = null;
      if (leading) {
        borrowedLeadingTrivia = leadingTrivia;
        leadingTrivia = null;
      }
      if (trailing) {
        borrowedTrailingTrivia = trailingTrivia;
        trailingTrivia = null;
      }

      var result = new Token(line, col) {
        filename = filename,
        kind = kind,
        pos = pos,
        trailingTrivia = borrowedTrailingTrivia,
        leadingTrivia = borrowedLeadingTrivia,
        val = val
      };
      return result;
    }
    
    public bool IsValid
    {
      get { return this._filename != null; }
    }
  }
}