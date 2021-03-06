{-# LANGUAGE OverloadedStrings #-}

module Commands
( respond
)
where

import qualified Data.ByteString.Char8 as B
import Data.Maybe (listToMaybe)
import Data.UUID (fromString)
import Data.UUID.V4 (nextRandom)
import System.IO (Handle)
import Control.Applicative ((<$>))
import Control.Monad.IO.Class
import Control.Monad.State
import Control.Monad.Except
import Control.Monad.Reader

import Messages
import Game
import Actions

respond :: Message -> Handle -> GameState -> IO GameState
respond message handle state = snd <$> runStateT (runReaderT (cmd (command message) handle) message) state

cmd :: B.ByteString -> Handle -> ReaderT Message (StateT GameState IO) ()

cmd "action" = \handle -> do
    message <- ask
    if length (mParts message) < 2
    then invalid handle
    else get >>= liftIO . runAction handle message >>= put

cmd "robot_stopped" = \handle -> do
    message <- ask
    if length (mParts message) /= 1
    then invalid handle
    else do
        let idPart = head $ mParts message
        modify . changeRobot idPart $ \r -> r { status = Off }

cmd _ = invalid

complain :: B.ByteString -> Handle -> ReaderT Message (StateT GameState IO) ()
complain err handle = undefined

invalid :: Handle -> ReaderT Message (StateT GameState IO) ()
invalid handle = liftIO . (flip sendInvalid handle) =<< ask
