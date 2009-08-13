# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Tourniquet
  class AlreadyBound < Exception; end
  class CircularDependency < Exception; end
  class MustBeSymbol < Exception; end
  class NotFound < Exception; end
end
