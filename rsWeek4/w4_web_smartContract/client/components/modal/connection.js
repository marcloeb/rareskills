import { Dialog, Transition } from "@headlessui/react";
import { Fragment, useState, forwardRef, useImperativeHandle } from "react";
import { clsx } from "clsx";

const ConnectionModal = forwardRef(({ connect, isConnect }, ref) => {
  const [isConnectVisible, setIsConnectVisible] = useState(true);
  let [isOpen, setIsOpen] = useState(true);
  let [title, setTitle] = useState("Select Network:");
  let [descripton, setDescripton] = useState("Please connect in Metamask to the Polygon Main network.");
  let [buttonText, setButtonText] = useState("Connect");

  function closeModal() {
    setIsOpen(false);
  }

  function openModal() {
    setIsOpen(true);
  }

  function performActionOnInput() {
    closeModal();
    if (isConnect) {
      connect();
    } else {
      //do nothing
    }
  }

  useImperativeHandle(ref, () => ({
    reopenModal() {
      setIsConnectVisible(false);
      openModal();
    },
    setTitleAndDescAction(title, desc, action) {
      setTitle(title);
      setDescripton(desc);
      if (action !== undefined) {
        isConnect = false;
        setButtonText(action);
      }
    },
  }));

  return (
    <>
      <Transition appear show={isOpen} as={Fragment}>
        <Dialog as="div" className="relative z-10" onClose={closeModal}>
          <Transition.Child
            as={Fragment}
            enter="ease-out duration-300"
            enterFrom="opacity-0"
            enterTo="opacity-100"
            leave="ease-in duration-200"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
          >
            <div className="fixed inset-0 bg-black bg-opacity-25" />
          </Transition.Child>

          <div className="fixed inset-0 overflow-y-auto">
            <div className="flex min-h-full items-center justify-center p-4 text-center">
              <Transition.Child
                as={Fragment}
                enter="ease-out duration-300"
                enterFrom="opacity-0 scale-95"
                enterTo="opacity-100 scale-100"
                leave="ease-in duration-200"
                leaveFrom="opacity-100 scale-100"
                leaveTo="opacity-0 scale-95"
              >
                <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                  <Dialog.Title as="h3" className="text-center text-lg font-medium leading-6 text-gray-900">
                    {title}
                  </Dialog.Title>
                  <div className="mt-2">
                    <p className="text-center text-sm text-gray-500">{descripton}</p>
                  </div>

                  <div className="mt-4">
                    <button
                      type="button"
                      className={clsx(
                        { invisible: !isConnectVisible },
                        "text-center",
                        "w-full",
                        "width-full",
                        "inline-flex",
                        "justify-center",
                        "rounded-md",
                        "border",
                        "border-transparent",
                        "bg-blue-100",
                        "px-4",
                        "py-2",
                        "text-sm",
                        "font-medium",
                        "text-blue-900",
                        "hover:bg-blue-200",
                        "focus:outline-none",
                        "focus-visible:ring-2",
                        "focus-visible:ring-blue-500",
                        "focus-visible:ring-offset-2"
                      )}
                      onClick={() => {
                        performActionOnInput();
                      }}
                    >
                      {buttonText}
                    </button>
                  </div>
                </Dialog.Panel>
              </Transition.Child>
            </div>
          </div>
        </Dialog>
      </Transition>
    </>
  );
});
export default ConnectionModal;
