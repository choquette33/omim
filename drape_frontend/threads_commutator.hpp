#pragma once

#include "drape/pointers.hpp"
#include "std/map.hpp"

namespace df
{

class Message;
enum class MessagePriority;
class MessageAcceptor;

class ThreadsCommutator
{
public:
  enum ThreadName
  {
    RenderThread,
    ResourceUploadThread
  };

  void RegisterThread(ThreadName name, MessageAcceptor *acceptor);
  void PostMessage(ThreadName name, drape_ptr<Message> && message, MessagePriority priority);

private:
  typedef map<ThreadName, MessageAcceptor *> TAcceptorsMap;
  TAcceptorsMap m_acceptors;
};

} // namespace df
